public abstract class RyModel {
	
	// Map of validators that should automatically be applied to fields of a certain type
	public static map<string,list<string>> data_type_validators {
		get {
			if (data_type_validators == null) {
				data_type_validators = new map<string,list<string>>();
				data_type_validators.put('number', new list<string>{'isNumber'});
				data_type_validators.put('url', new list<string>{'isURL'});
				data_type_validators.put('email', new list<string>{'isEmail'});
				data_type_validators.put('date', new list<string>{'isDate'});
			}
			return data_type_validators;
		}
	}

	/* This class is used to represent each field/attribute for a model in a schema */
	public virtual class SchemaNode {
		
		public String sf_object;
		public String sf_field;

		public String name { get; set; }
		public String namespace { get; set; }
		public String suffix { get; set; }
		public String label { get; set; }
		public String description { get; set; }

		public String data_type { 
			get {
				if (sf_object != null && sf_field != null && data_type_from_sf == true) {
					return auto_data_type;
				}
				return data_type;
			}
			set;
		}

		// Assign data type from sf_field definition
		public Boolean data_type_from_sf { get; set; }
		private String auto_data_type {
			get {
				if (sf_object != null && sf_field != null) {
					auto_data_type = RyModel.castField(sf_field, sf_object);
				} else {
					auto_data_type = null;
				}
				return auto_data_type;
			}
			set;
		}
		
		public Boolean required { get; set; }
		
		public String default_value { get; set; }
		
		public String current_value { get; set; }
		
		// Automatically assign validator from sObject
		public Boolean auto_validate { get; set; }
		// Allows for adding of a single validator by string lookup
		public String validator { get; set; }
		// Allows for adding of multiple validators by List of strings
		public List<String> validators { get; set; }
		// Once the form has been setup the instanciated validator classes are added
		// to this List
		public List<RyValidator.Base> ryvalidators { get; set; }
		
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
			if (this.data_type == null) this.data_type = 'text';
			if (this.required == null) this.required = false;
			if (this.data_type_from_sf == null) {
				if (this.sf_field != null && this.sf_object != null) {
					this.data_type_from_sf = true;
				} else {
					this.data_type_from_sf = false;
				}
			}
			if (this.default_value == null) this.default_value = '';
			if (this.validator == null) this.validator = '';
			if (this.validators == null) this.validators = new List<string>();
			
			if (this.error == null) this.error = '';

		}
		
		public SchemaNode() {
			setup();
		}
		
		public SchemaNode(String sf_field) {
			this.sf_field = sf_field;
			setup();
		}

		public SchemaNode(String name, String label, String sf_field) {
			this.name = name;
			this.label = label;
			this.sf_field = sf_field;
		}

		public virtual String validate(Map<String, String> params) {
			
			for (RyValidator.Base validator : this.ryvalidators) {
        		
        		// Run validator
        		validator.validate(this.current_value, params);
				
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

		public virtual void add_validator(String validator) {
			if (validator != null) {
				this.validators.add(validator);
			}
		}

		public virtual void setup_validators() {
			Set<string> validator_set = new Set<String>();

			validator_set.addAll(this.validators);
			
			//  - Required fields
			if (this.required) {
				validator_set.add('Required');
			}
			
			//  - For data types
			if (this.data_type != null) {
				if (RyModel.data_type_validators.containsKey(this.data_type)) {
					validator_set.addAll(RyModel.data_type_validators.get(this.data_type));
				}
			}
			
			//  - Manually added
			if (this.validator != null && this.validator != '') {
				validator_set.add(this.validator);
			}
			
			//  - Max Length
			if (this.max > 0) {
				validator_set.add('maxLength');
			}
			
			this.validators = new List<String>();
			
			this.ryvalidators = new list<RyValidator.Base>();
			
			for (String v_string : validator_set) {
				JSONParser parser = JSON.createParser('{}');
				Type vClass;
				if (!v_string.contains('.')) {
        			vClass = Type.forName('RyValidator.'+v_string);
				}
        		RyValidator.Base validator = (RyValidator.Base)parser.readValueAs(vClass);
        		if (this.max > 0) {
        			validator.max = this.max;
        		}
        		validator.setup();
        		this.ryvalidators.add(validator);

			}
		}
		
	}
	
	/* This class represents the model. Primarily it holds a map of SchemaNodes */
	public class ModelSchema {
		
		private Map<String, SchemaNode> nodes;
		public String sf_object;
		public Boolean validate_nodes;
		public Boolean auto_validate;
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

		public void addNode(String key, String sf_field) {
			this.nodes.put(key, new SchemaNode(sf_field));
		}
		
		public void addNode(String key, SchemaNode node) {
			this.nodes.put(key, node);
		}
		
		public void addNode(SchemaNode node) {
			if (node.name != '') {
				this.nodes.put(node.name, node);
			} else {
				this.nodes.put(node.sf_field, node);
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
		public string error;
	}
	
	// Take the bland map of strings and work the magic */
	public static ProcessedResponse processModel(map<string, string> model, ModelSchema model_schema) {

		ProcessedResponse response = new ProcessedResponse();

		// First off, if there is no sf_object set on the schema, we should not do anything
		if (model_schema.sf_object == null || model_schema.sf_object == '') {
			response.error = 'ModelSchema.sf_object cannot be null or empty.';
			response.success = false;
			return response;
		}

		// Validate
		if (model_schema.validate_nodes == null || model_schema.validate_nodes == true) {
			for (SchemaNode node : model_schema.getNodes().values()) {

			}
		}
		
		map<string, string> clean_model = new map<string, string>();
		
		for (String k : model.keySet()) {
			String value = model.get(k);
			
			String field;
			
			if (model_schema.getNodes().containsKey(k)) {
				field = model_schema.getNodes().get(k).sf_field;
				clean_model.put(field, value);
			}
			
		}
		
		if (!clean_model.isEmpty()) {
	        
	        String to_parse = '{}';
	        String id_to_set;
	        if (clean_model.containsKey('Id')) {
	        	id_to_set = clean_model.get('Id');
	        	clean_model.remove('Id');
	        }
	        if (id_to_set != null && id_to_set != '') {
	        	to_parse = '{ "Id": "' + id_to_set + '" } ';
	        }
	        
	        JSONParser parser = JSON.createParser(to_parse);
			Type ob_type = Type.forName(model_schema.sf_object);
			sObject sf_obj = (sObject)parser.readValueAs(ob_type);
			
			for (String field_name : clean_model.keySet()) {
				String field_type = getFieldType(model_schema.sf_object, field_name);
				if (field_name != 'Id' && field_name != 'id') {
					try {
						sf_obj = setValue(clean_model.get(field_name), field_name, sf_obj);
					} catch(exception e) {
						response.success = false;
						response.error = e.getMessage();
					}
				}
			}
			if (response.success == null) {
				try {
					if (model_schema.action == 'upsert') {
						upsert sf_obj;
					} else if (model_schema.action == 'update') {
						update sf_obj;
					} else if (model_schema.action == 'insert') {
						insert sf_obj;
					} else if (model_schema.action == 'return') {
						// Do nothing
					}
					response.success = true;
				} catch (exception e) {
					response.success = false;
					response.error = e.getMessage();
				}
			}
			response.obj = sf_obj;
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
	public static string castField(String field_name, sObject sf_obj) {
		String sobject_name = sf_obj.getSObjectType().getDescribe().getName();
		return castField(field_name, sobject_name);
	}
	public static string castField(String field_name, String sobject_name) {
		
		String field_type = getFieldType(sobject_name, field_name);
		
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
		
		if (field_type == 'URL') {
			return 'url';
		} else if (field_type == 'EMAIL') {
			return 'email';
		} else if (strings.contains(field_type)) {
			return 'text';
		} else if (decimals.contains(field_type)) {
			return 'decimal';
		} else if (field_type == 'INTEGER') {
			return 'number';
		} else if (field_type == 'DATE') {
			return 'date';
		} else if (field_type == 'CHECKBOX' || field_type == 'BOOLEAN') {
			return 'boolean';
		}
		
		return null;
	}
	
	// Attempt to convert the string to the correct value and set it on the sObject */
	public static sObject setValue(String value, String field_name, sObject sf_obj) {
		
		String casted = RyModel.castField(field_name, sf_obj);
		
		if (casted == 'text' || casted == 'url' || casted == 'email') {
			sf_obj.put(field_name, String.valueOf(value));
		} else if (casted == 'decimal') {
			sf_obj.put(field_name, Decimal.valueOf(value));
		} else if (casted == 'number') {
			sf_obj.put(field_name, Integer.valueOf(value));
		} else if (casted == 'date') {
			if (value.contains('-')) {
				sf_obj.put(field_name, Date.valueOf(value));
			} else if (value.contains('/')) {
				sf_obj.put(field_name, Date.parse(value));
			}
		} else if (casted == 'boolean') {
			if (value == '' || value == 'false') {
				sf_obj.put(field_name, false);
			} else if (value == null) {

			} else {
				sf_obj.put(field_name, true);
			}
		}
		
		return sf_obj;
		
	}
	
	// Describes the field and returns the type 
	public static String getFieldType(String sobject_name, String field_name) {
		String field_type = '';
		try {
			field_type = Schema.getGlobalDescribe().get(sobject_name).getDescribe().fields.getMap().get(field_name).getDescribe().getType().name();
		} catch (Exception e) {
			// TODO: do something
		}
		return field_type;
	}

	// Returns a query with which to select an sObject with the same fields as in a model
	public static String getObjQuery(RyModel.ModelSchema model_schema) {
		String query = 'SELECT ';
		Integer i = 1;
		for (RyModel.SchemaNode node : model_schema.getNodes().values()) {
			query += node.sf_field;
			if (i != model_schema.getNodes().values().size()) {
				query += ', ';
			}
			i++;
		}
		query += ' FROM ' + model_schema.sf_object;
		return query;
	}

}