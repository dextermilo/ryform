public with sharing class RyForm {
	
	public class RyField {
		
		public String name { get; set; }
		public String label { get; set; }
		public String description { get; set; }
		public String data_type { get; set; }
		public RyWidget.Base widget { get; set; }
		public Boolean required { get; set; }
		public String default_value { get; set; }
		public String validator { get; set; }
		public list<String> validators { get; set; }
		public list<RyValidator.Base> ryvalidators { get; set; }
		public String error { get; set; }
		
		// Rules (length for text fields, values for numbers)
		public Integer max;
		
		public String rendered {
			get {
				return render();
			}
			set;	
		}
		
		public void setup() {
			if (this.name == null) this.name = '';
			if (this.label == null) this.label = '';
			if (this.description == null) this.description = '';
			if (this.data_type == null) this.data_type = 'text';
			if (this.widget == null) this.widget = new RyWidget.TextLine();
			if (this.required == null) this.required = true;
			if (this.default_value == null) this.default_value = '';
			if (this.validator == null) this.validator = '';
			if (this.validators == null) this.validators = new list<string>();
			
			if (this.error == null) this.error = '';
			
		}
		
		public RyField(Map<String, String> struct) {
			
			for (String k : struct.keySet()) {
				
				if (k == 'name') {
					this.name = struct.get(k);
				}
				
				if (k == 'label') {
					this.label = struct.get(k);
				}
				
				if (k == 'description') {
					this.description = struct.get(k);
				}
				
				if (k == 'data_type') {
					this.data_type = struct.get(k);
				}
				
				if (k == 'required') {
					String value = struct.get(k);
					if (value == 'true' || value == 'false') {
						this.required = Boolean.valueOf(struct.get(k));
					}
				}
				
				if (k == 'default_value') {
					this.default_value = struct.get(k);
				}
				
				if (k == 'validator') {
					this.validator = struct.get(k);
				}
				
				
			}
			
			setup();
			
		}
		
		public String render() {
			
			return '<div class="control-group '+(this.error != null && this.error != '' ? 'error' : '')+'"><label class="control-label" for="'+this.name+'">'+this.label+'</label><div class="controls">'+this.widget.render(this.name, this.description, this.default_value, this.error)+'</div></div>';
			
		}
		
		public void widgitify() {
			
			if (this.widget != null) {

				String widget_json = JSON.serialize(this.widget);
				JSONParser parser = JSON.createParser(widget_json);
				Type widget_class;
				if (!this.widget.type.contains('.')) {
        			widget_class = Type.forName('RyWidget.'+this.widget.type);
				}
        		this.widget = (RyWidget.Base)parser.readValueAs(widget_class);
				
			}
			
		}
		
	}
	
	
	public list<RyField> field_list { get; set; }
	
	public list<RyModel.ModelSchema> models;
	
	public map<string,string> errors { get; set; }
	
	public boolean has_errors {
		get {
			return !errors.isEmpty();
		}
	}
	
	public map<string,string> params { get; set; }
	
	public static map<string,list<string>> data_type_validators {
		get {
			if (data_type_validators == null) {
				data_type_validators = new map<string,list<string>>();
				data_type_validators.put('number', new list<string>{'isNumber'});
			}
			return data_type_validators;
		}
	}
	
	public RyForm() {
		field_list = new list<RyField>();
		errors = new map<string, string>();
		models = new list<RyModel.ModelSchema>();
		params = new map<string, string>();
	}
	
	public void setup() {
		// Reset errors
		errors = new map<string,string>();
		
		for (RyField field : field_list) {
			
			// Set current value
			field.widget.current_value = field.widget.extract(params);
			
			// Setup validators
			Set<string> validator_set = new set<string>();
			validator_set.addAll(field.validators);
			
			//  - Required fields
			if (field.required) {
				validator_set.add('Required');
			}
			
			//  - For data types
			if (field.data_type != null) {
				if (data_type_validators.containsKey(field.data_type)) {
					validator_set.addAll(data_type_validators.get(field.data_type));
				}
			}
			
			//  - Manually added
			if (field.validator != null && field.validator != '') {
				validator_set.add(field.validator);
			}
			
			field.validators = new list<string>();
			field.validators.addAll(validator_set);
			field.ryvalidators = new list<RyValidator.Base>();
			
			//  - Max Length
			if (field.max > 0) {
				RyValidator.maxLength max_length = new RyValidator.maxLength();
				max_length.max = field.max;
				max_length.setup();
				field.ryvalidators.add(max_length);
			}
			
			for (String v_string : field.validators) {
				JSONParser parser = JSON.createParser('{}');
				Type vClass;
				if (!v_string.contains('.')) {
        			vClass = Type.forName('RyValidator.'+v_string);
				}
        		RyValidator.Base validator = (RyValidator.Base)parser.readValueAs(vClass);
        		validator.setup();
        		field.ryvalidators.add(validator);
        		if (validator.css_class != null && validator.css_class != '') {
        			field.widget.css_classes.add(validator.css_class);
        		}
			}
			//for (String vd)
			//field.widget.css_classes.addAll()
		}
	}
	
	public Boolean validate(map<string,string> params) {
		
		errors = new map<string,string>();
		
		// Run validation
		for (RyField field : field_list) {
			String value = field.widget.extract(params);
			
			for (RyValidator.Base validator : field.ryvalidators) {
        		
        		
        		// Run validator
        		validator.validate(value, params);
				
        		if (!validator.valid) {
        			field.error = validator.message;
        			errors.put(field.name, validator.message);
        		}
					
			}
			
			
		}
		
		for (RyField field : field_list) {
			if (!errors.containsKey(field.name)) {
				field.error = '';
			}
		}
		
		
		if (!errors.isEmpty()) {
			return false;
		}
		return true;
	
	}

}