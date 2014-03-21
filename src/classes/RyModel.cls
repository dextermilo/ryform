public abstract class RyModel {
    
    /* This class represents the model. Primarily it holds a map of RySchema.Nodes */
    public class ModelSchema {
        
        private Map<String, RySchema.Node> nodes;
        public String sfObject;
        public Boolean validateNodes;
        public Boolean autoValidate;
        public String action {
            Get {
                if (this.action == null) {
                    action = 'upsert';
                }
                return action;
            }
            Set;
        }
        
        public ModelSchema() {
            this.nodes = new Map<String, RySchema.Node>();
        }

        public void addNode(String key) {
            this.nodes.put(key, new RySchema.Node(key));
        }

        public void addNode(String key, String sfField) {
            this.nodes.put(key, new RySchema.Node(sfField));
        }
        
        public void addNode(String key, RySchema.Node node) {
            this.nodes.put(key, node);
        }
        
        public void addNode(RySchema.Node node) {
            if (node.key != '') {
                this.nodes.put(node.key, node);
            } else {
                this.nodes.put(node.sfField, node);
            }
        }
        
        public Map<String, RySchema.Node> getNodes() {
            return this.nodes;
        }

    }
    
    /* Response from a processModel call */
    public class ProcessedResponse {
        public sObject obj;
        public Boolean success;
        public String error;
    }
    
    // Take the bland map of strings and work the magic */
    public static ProcessedResponse processModel(Map<String, String> model, ModelSchema modelSchema) {

        ProcessedResponse response = new ProcessedResponse();

        // First off, if there is no sfObject set on the schema, we should not do anything
        if (modelSchema.sfObject == null || modelSchema.sfObject == '') {
            response.error = 'ModelSchema.sfObject cannot be null or empty.';
            response.success = false;
            return response;
        }

        // Validate
        if (modelSchema.validateNodes == null || modelSchema.validateNodes == true) {
            for (RySchema.Node node : modelSchema.getNodes().values()) {

            }
        }
        
        Map<String, String> cleanModel = new Map<String, String>();
        
        for (String k : model.keySet()) {
            String value = model.get(k);
            
            String field;
            
            if (modelSchema.getNodes().containsKey(k)) {
                field = modelSchema.getNodes().get(k).sfField;
                cleanModel.put(field, value);
            }
            
        }
        
        if (!cleanModel.isEmpty()) {
            
            String toParse = '{}';
            String idToSet;
            if (cleanModel.containsKey('Id')) {
                idToSet = cleanModel.get('Id');
                cleanModel.remove('Id');
            }
            if (idToSet != null && idToSet != '') {
                toParse = '{ "Id": "' + idToSet + '" } ';
            }
            
            JSONParser parser = JSON.createParser(toParse);
            Type obType = Type.forName(modelSchema.sfObject);
            sObject sfObj = (sObject)parser.readValueAs(obType);
            
            for (String fieldName : cleanModel.keySet()) {
                String fieldType = getFieldType(modelSchema.sfObject, fieldName);
                if (fieldName != 'Id' && fieldName != 'id') {
                    try {
                        sfObj = setValue(cleanModel.get(fieldName), fieldName, sfObj);
                    } catch(exception e) {
                        response.success = false;
                        response.error = e.getMessage();
                    }
                }
            }
            if (response.success == null) {
                try {
                    if (modelSchema.action == 'upsert') {
                        upsert sfObj;
                    } else if (modelSchema.action == 'update') {
                        update sfObj;
                    } else if (modelSchema.action == 'insert') {
                        insert sfObj;
                    } else if (modelSchema.action == 'return') {
                        // Do nothing
                    }
                    response.success = true;
                } catch (exception e) {
                    response.success = false;
                    response.error = e.getMessage();
                }
            }
            response.obj = sfObj;
            return response;
        }
        return null;
    }

    public static ProcessedResponse processModel(Map<String, Object> model, ModelSchema schema) {
        if (model != null) {
            Map<String, String> input = new Map<String, String>();
            for (String key : model.keySet()) {
                input.put(key, (String)String.valueOf(model.get(key)));
            }
            return processModel(input, schema);
        }
        return null;
    }
    
    // Cast the value off of SF definition, convert it to less SF specific cast */
    public static String castField(String fieldName, sObject sfObj) {
        String sObjectName = sfObj.getSObjectType().getDescribe().getName();
        return castField(fieldName, sObjectName);
    }
    public static String castField(String fieldName, String sObjectName) {
        
        String fieldType = getFieldType(sObjectName, fieldName);
        
        Set<String> strings = new Set<String> {
            'STRING',
            'PHONE',
            'PICKLIST',
            'MULTIPICKLIST',
            'TEXTAREA',
            'EMAIL',
            'ENCRYPTEDSTRING',
            'ID',
            'REFERENCE',
            'URL'
        };
        
        Set<String> decimals = new Set<String> {
            'CURRENCY',
            'PERCENT',
            'DOUBLE'
        };
        
        if (fieldType == 'URL') {
            return 'url';
        } else if (fieldType == 'EMAIL') {
            return 'email';
        } else if (strings.contains(fieldType)) {
            return 'text';
        } else if (decimals.contains(fieldType)) {
            return 'decimal';
        } else if (fieldType == 'INTEGER') {
            return 'number';
        } else if (fieldType == 'DATE') {
            return 'date';
        } else if (fieldType == 'CHECKBOX' || fieldType == 'BOOLEAN') {
            return 'Boolean';
        }
        
        return null;
    }
    
    // Attempt to convert the String to the correct value and set it on the sObject */
    public static sObject setValue(String value, String fieldName, sObject sfObj) {
        
        String casted = RyModel.castField(fieldName, sfObj);
        
        if (casted == 'text' || casted == 'url' || casted == 'email') {
            sfObj.put(fieldName, String.valueOf(value));
        } else if (casted == 'decimal') {
            sfObj.put(fieldName, Decimal.valueOf(value));
        } else if (casted == 'number') {
            sfObj.put(fieldName, Integer.valueOf(value));
        } else if (casted == 'date') {
            if (value.contains('-')) {
                sfObj.put(fieldName, Date.valueOf(value));
            } else if (value.contains('/')) {
                sfObj.put(fieldName, Date.parse(value));
            }
        } else if (casted == 'Boolean') {
            if (value == '' || value == 'false') {
                sfObj.put(fieldName, false);
            } else if (value == null) {

            } else {
                sfObj.put(fieldName, true);
            }
        }
        
        return sfObj;
        
    }
    
    // Describes the field and returns the type 
    public static String getFieldType(String sObjectName, String fieldName) {
        String fieldType = '';
        try {
            fieldType = Schema.getGlobalDescribe()
                .get(sObjectName).getDescribe()
                .fields.getMap().get(fieldName)
                .getDescribe().getType().name();
        } catch (Exception e) {
            // TODO: do something
        }
        return fieldType;
    }

    // Returns a query with which to select an sObject with the same fields as in a model
    public static String getObjQuery(RyModel.ModelSchema modelSchema) {
        String query = 'SELECT ';
        Integer i = 1;
        for (RySchema.Node node : modelSchema.getNodes().values()) {
            query += node.sfField;
            if (i != modelSchema.getNodes().values().size()) {
                query += ', ';
            }
            i++;
        }
        query += ' FROM ' + modelSchema.sfObject;
        return query;
    }

}