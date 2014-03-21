public abstract class RyModel {
    
    // Map of validators that should automatically be applied to fields of a certain type
    public static Map<String, List<String>> dataTypeValidators {
        get {
            if (dataTypeValidators == null) {
                dataTypeValidators = new Map<String, List<String>>();
                dataTypeValidators.put('number', new List<String>{'isNumber'});
                dataTypeValidators.put('url', new List<String>{'isURL'});
                dataTypeValidators.put('email', new List<String>{'isEmail'});
                dataTypeValidators.put('date', new List<String>{'isDate'});
            }
            return dataTypeValidators;
        }
    }

    /* This class is used to represent each field/attribute for a model in a schema */
    public virtual class SchemaNode {
        
        public String sfObject;
        public String sfField;

        public String name { get; set; }
        public String namespace { get; set; }
        public String suffix { get; set; }
        public String label { get; set; }
        public String description { get; set; }

        public String dataType { 
            get {
                if (sfObject != null && sfField != null && dataTypeFormSf == true) {
                    return autoDataType;
                }
                return dataType;
            }
            set;
        }

        // Assign data type from sfField definition
        public Boolean dataTypeFormSf { get; set; }
        private String autoDataType {
            get {
                if (sfObject != null && sfField != null) {
                    autoDataType = RyModel.castField(sfField, sfObject);
                } else {
                    autoDataType = null;
                }
                return autoDataType;
            }
            set;
        }
        
        public Boolean required { get; set; }
        public String defaultValue { get; set; }
        public String currentValue { get; set; }
        
        // Automatically assign validator from sObject
        public Boolean autoValidate { get; set; }
        // Allows for adding of a single validator by String lookup
        public String validator { get; set; }
        // Allows for adding of multiple validators by List of strings
        public List<String> validators { get; set; }
        // Once the form has been setup the instanciated validator classes are added
        // to this List
        public List<RyValidator.Base> ryValidators { get; set; }
        
        // The error message if any associated with this field
        public String error { get; set; }
        
        // Rules (length for text fields, values for numbers)
        public Integer max;
        
        // This is not done in the standard constructor because contructors are
        // not fired when the class is instantiated using JSON parser.
        public virtual void setup() {
            if (this.name == null) this.name = '';
            if (this.namespace == null) this.namespace = '';
            if (this.suffix == null) this.suffix = '';
            if (this.label == null) this.label = '';
            if (this.description == null) this.description = '';
            if (this.dataType == null) this.dataType = 'text';
            if (this.required == null) this.required = false;
            if (this.dataTypeFormSf == null) {
                if (this.sfField != null && this.sfObject != null) {
                    this.dataTypeFormSf = true;
                } else {
                    this.dataTypeFormSf = false;
                }
            }
            if (this.defaultValue == null) this.defaultValue = '';
            if (this.validator == null) this.validator = '';
            if (this.validators == null) this.validators = new List<String>();
            
            if (this.error == null) this.error = '';

        }
        
        public SchemaNode() {
            setup();
        }
        
        public SchemaNode(String sfField) {
            this.sfField = sfField;
            setup();
        }

        public SchemaNode(String name, String label, String sfField) {
            this.name = name;
            this.label = label;
            this.sfField = sfField;
        }

        public virtual String validate(Map<String, String> params) {
            
            for (RyValidator.Base validator : this.ryValidators) {
                
                // Run validator
                validator.validate(this.currentValue, params);
                
                if (!validator.valid) {
                    this.error = validator.message;
                    return this.error;
                }
                    
            }
            return '';
            
        }

        public virtual String validate() {
            return this.validate(new Map<String, String>());
        }

        public virtual void addValidator(String validator) {
            if (validator != null) {
                this.validators.add(validator);
            }
        }

        public virtual void setupValidators() {
            Set<string> validatorSet = new Set<String>();

            validatorSet.addAll(this.validators);
            
            //  - Required fields
            if (this.required) {
                validatorSet.add('Required');
            }
            
            //  - For data types
            if (this.dataType != null) {
                if (RyModel.dataTypeValidators.containsKey(this.dataType)) {
                    validatorSet.addAll(RyModel.dataTypeValidators.get(this.dataType));
                }
            }
            
            //  - Manually added
            if (this.validator != null && this.validator != '') {
                validatorSet.add(this.validator);
            }
            
            //  - Max Length
            if (this.max > 0) {
                validatorSet.add('maxLength');
            }
            
            this.validators = new List<String>();
            
            this.ryValidators = new List<RyValidator.Base>();
            
            for (String vString : validatorSet) {
                JSONParser parser = JSON.createParser('{}');
                Type vClass;
                if (!vString.contains('.')) {
                    vClass = Type.forName('RyValidator.'+vString);
                }
                RyValidator.Base validator = (RyValidator.Base)parser.readValueAs(vClass);
                if (this.max > 0) {
                    validator.max = this.max;
                }
                validator.setup();
                this.ryValidators.add(validator);

            }
        }
        
    }
    
    /* This class represents the model. Primarily it holds a map of SchemaNodes */
    public class ModelSchema {
        
        private Map<String, SchemaNode> nodes;
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
            this.nodes = new Map<String, SchemaNode>();
        }

        public void addNode(String key) {
            this.nodes.put(key, new SchemaNode(key));
        }

        public void addNode(String key, String sfField) {
            this.nodes.put(key, new SchemaNode(sfField));
        }
        
        public void addNode(String key, SchemaNode node) {
            this.nodes.put(key, node);
        }
        
        public void addNode(SchemaNode node) {
            if (node.name != '') {
                this.nodes.put(node.name, node);
            } else {
                this.nodes.put(node.sfField, node);
            }
        }
        
        public Map<String, SchemaNode> getNodes() {
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
            for (SchemaNode node : modelSchema.getNodes().values()) {

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
        for (RyModel.SchemaNode node : modelSchema.getNodes().values()) {
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