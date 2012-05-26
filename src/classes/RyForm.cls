public virtual class RyForm {

	public class RyFieldset {
		public String name { get; set; }
		public list<String> fields { get; set; }

		public RyFieldset() {
			fields = new List<String>();
		}
	}
	
	public list<RyModel.ModelSchema> models;
	public boolean auto_model;
	public String sf_object;
	public String action;

	public map<string,string> errors { get; set; }
	
	public boolean has_errors {
		get {
			return !errors.isEmpty();
		}
	}

	// Fieldsets, right now implemented as list<string> of list<string>
	public List<RyFieldset> fieldsets { get; set; }
	
	// Map of parameters, i.e. raw form input values, that are passed into the form
	public map<string,string> params { get; set; }
	
	// Map of validators that should automatically be applied to fields of a certain type
	public static map<string,list<string>> data_type_validators {
		get {
			if (data_type_validators == null) {
				data_type_validators = new map<string,list<string>>();
				data_type_validators.put('number', new list<string>{'isNumber'});
			}
			return data_type_validators;
		}
	}
	
	// The list of fields on our form
	public list<RyField> fields { get; set; }
	
	// Prefix to apply to field names when they are rendered to avoid conflicts with other forms
	public String namespace { get; set; }
	public String suffix { get; set; }

	public String rendered {
		Get {
			return render();
		}
	}
	

	public RyForm() {
		// Constructor.  Simply sets up base properties.
		set_defaults();
	}


	public virtual void set_defaults() {
		if (fields == null) fields = new list<RyField>();
		if (errors == null) errors = new map<string, string>();
		if (models == null) models = new list<RyModel.ModelSchema>();
		if (params == null) params = new map<string, string>();
		if (fieldsets == null) fieldsets = new List<RyFieldset>();
		if (namespace == null) namespace = '';
		if (suffix == null) suffix = '';
	}
	

	public virtual void add_field(RyField field) {
		// Method to add a new field to the list. Prevents duplicate names.

		if (get_field(field.name) == null) {
			fields.add(field);
		}
	}
	public virtual void add_field(String name, String label) {
		// Method to create then add a field.

		RyField field = new RyField();
		field.name = name;
		field.label = label;
		add_field(field);
	}
	
	
	public virtual RyField get_field(String name) {
		// Method to get a field by name

		if (!fields.isEmpty()) {
			for (RyField field : fields) {
				if (field.name == name) {
					return field;
				}
			}
		}
		return null;
	}
	

	public virtual void setup() {
		// This method sets up the form, including validation and errors.

		// Reset errors
		errors = new map<string,string>();
		
		for (RyField field : fields) {
			
			//Namespace
			field.namespace = this.namespace;
			field.suffix = this.suffix;

			// Set current value
			field.current_value = field.widget.extract(params);
			
			field.setup_validators();
		}
	}
	

	public virtual Boolean validate() {
		// Run all validators on all fields and fill map of field name to error message.

		errors = new map<string,string>();
		
		// Run validation
		for (RyField field : fields) {
			
			String error = field.validate(this.params);

			if (error != null && error != '') {
    			errors.put(field.name, error);
    		}
    		
		}
		
		for (RyField field : fields) {
			if (!errors.containsKey(field.name)) {
				field.error = '';
			}
		}
		
		
		if (!errors.isEmpty()) {
			return false;
		}
		return true;
	
	}
	
	
	public virtual List<RyModel.ProcessedResponse> process() {
		// Shortcut method to validate and process all models
		
		list<RyModel.ProcessedResponse> responses = new list<RyModel.ProcessedResponse>();

		if (this.validate()) {

			Boolean status = true;
			
			if (this.auto_model == true && this.sf_object != null) {
				responses.add(RyModel.processModel(this.params, this.generate_model()));
			} else {
				if (!this.models.isEmpty()) {
					for (RyModel.ModelSchema model : this.models) {
						responses.add( RyModel.processModel(params, model) );
					}
				
				}
			}
			return responses;
			
		}
		return null;
		
	}


	public virtual String render() {

		String form_tmpl = '##FIELDS## ##FIELDSETS##';
		String fieldset_tmpl = '<fieldset>##LEGEND## ##FIELDS##</fieldset>';
		String legend_tmpl = '<legend>##NAME##</legend>';
		String output = form_tmpl;
		String fieldsets_output = '';
		String fields_output = '';
		Set<String> rendered_fields = new Set<String>();

		// Fieldsets
		if (!fieldsets.isEmpty() && !fields.isEmpty()) {

			for (RyFieldset fieldset : fieldsets) {

				if (fieldset.fields.isEmpty()) {
					continue;
				}

				String fieldset_output = fieldset_tmpl;
				String legend_output = legend_tmpl;
				String field_output = '';

				// Legend
				if (fieldset.name != '' && fieldset.name != null) {
					legend_output = legend_output.replace('##NAME##', fieldset.name);
				} else {
					legend_output = '';
				}
				fieldset_output = fieldset_output.replace('##LEGEND##', legend_output);

				// Fields
				for (String field_name : fieldset.fields) {
					if (!rendered_fields.contains(field_name)) {
						field_output += get_field(field_name).render();
						rendered_fields.add(field_name);
					}
				}
				fieldset_output = fieldset_output.replace('##FIELDS##', field_output);

				fieldsets_output += fieldset_output;
			}

		}

		output = output.replace('##FIELDSETS##', fieldsets_output);

		// Unallocated Fields
		if (!fields.isEmpty()) {
			
			for (RyField field : fields) {
				Boolean render_this = true;
				for (String field_name : rendered_fields) {
					if (field_name == field.name) {
						render_this = false;
					}
				}
				if (render_this) {
					fields_output += field.render();
				}
			}

		}

		output = output.replace('##FIELDS##', fields_output);

		return output;

	}

	private virtual RyModel.ModelSchema generate_model() {
		RyModel.ModelSchema schema = new RyModel.ModelSchema();
		schema.sf_object = this.sf_object;
		if (this.action != null) {
			schema.action = this.action;
		}
		Boolean has_id = false;
		for (RyField field : this.fields) {
			if (field.sf_field == null) {
				field.sf_field = field.name;
			}
			if (field.sf_field != null) {
				schema.addNode(field);
			}
			if (field.sf_field == 'Id') {
				has_id = true;
			}
		}
		if (!has_id) {
			schema.addNode('Id');
		}
		return schema;
	}

}