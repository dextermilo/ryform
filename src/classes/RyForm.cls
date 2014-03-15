public virtual class RyForm {

	public class RyFieldset {
		public String name { get; set; }
		public List<String> fields { get; set; }

		public RyFieldset() {
			fields = new List<String>();
		}
	}
	
	public List<RyModel.ModelSchema> models;
	public Boolean auto_model;
	public String sfObject;
	public String action;

	public Map<String, String> errors { get; set; }
	
	public Boolean has_errors {
		get {
			return !errors.isEmpty();
		}
	}

	// Fieldsets, right now implemented as List<String> of List<String>
	public List<RyFieldset> fieldsets { get; set; }
	
	// Map of parameters, i.e. raw form input values, that are passed into the form
	public Map<String, String> params { get; set; }
	
	// Map of validators that should automatically be applied to fields of a certain type
	public static Map<String, List<String>> dataTypeValidators {
		get {
			if (dataTypeValidators == null) {
				dataTypeValidators = new Map<String, List<String>>();
				dataTypeValidators.put('number', new List<String>{'isNumber'});
			}
			return dataTypeValidators;
		}
	}
	
	// The list of fields on our form
	public List<RyField> fields { get; set; }
	
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
		setDefaults();
	}


	public virtual void setDefaults() {
		if (fields == null) fields = new List<RyField>();
		if (errors == null) errors = new Map<String, String>();
		if (models == null) models = new List<RyModel.ModelSchema>();
		if (params == null) params = new Map<String, String>();
		if (fieldsets == null) fieldsets = new List<RyFieldset>();
		if (namespace == null) namespace = '';
		if (suffix == null) suffix = '';
	}
	

	public virtual void addField(RyField field) {
		// Method to add a new field to the list. Prevents duplicate names.

		if (getField(field.name) == null) {
			fields.add(field);
		}
	}
	public virtual void addField(String name, String label) {
		// Method to create then add a field.

		RyField field = new RyField();
		field.name = name;
		field.label = label;
		addField(field);
	}
	
	
	public virtual RyField getField(String name) {
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
		errors = new Map<String, String>();
		
		for (RyField field : fields) {
			
			//Namespace
			field.namespace = this.namespace;
			field.suffix = this.suffix;

			// Set current value
			field.currentValue = field.widget.extract(params);
			
			field.setupValidators();
		}
	}
	

	public virtual Boolean validate() {
		// Run all validators on all fields and fill map of field name to error message.

		errors = new Map<String, String>();
		
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
		
		List<RyModel.ProcessedResponse> responses = new List<RyModel.ProcessedResponse>();

		if (this.validate()) {

			Boolean status = true;
			
			if (this.auto_model == true && this.sfObject != null) {
				responses.add(RyModel.processModel(this.params, this.generateModel()));
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
		String fieldsetsOutput = '';
		String fieldsOutput = '';
		Set<String> renderedFields = new Set<String>();

		// Fieldsets
		if (!fieldsets.isEmpty() && !fields.isEmpty()) {

			for (RyFieldset fieldset : fieldsets) {

				if (fieldset.fields.isEmpty()) {
					continue;
				}

				String fieldsetOutput = fieldset_tmpl;
				String legendOutput = legend_tmpl;
				String fieldOutput = '';

				// Legend
				if (fieldset.name != '' && fieldset.name != null) {
					legendOutput = legendOutput.replace('##NAME##', fieldset.name);
				} else {
					legendOutput = '';
				}
				fieldsetOutput = fieldsetOutput.replace('##LEGEND##', legendOutput);

				// Fields
				for (String fieldName : fieldset.fields) {
					if (!renderedFields.contains(fieldName)) {
						fieldOutput += getField(fieldName).render();
						renderedFields.add(fieldName);
					}
				}
				fieldsetOutput = fieldsetOutput.replace('##FIELDS##', fieldOutput);

				fieldsetsOutput += fieldsetOutput;
			}

		}

		output = output.replace('##FIELDSETS##', fieldsetsOutput);

		// Unallocated Fields
		if (!fields.isEmpty()) {
			
			for (RyField field : fields) {
				Boolean renderThis = true;
				for (String fieldName : renderedFields) {
					if (fieldName == field.name) {
						renderThis = false;
					}
				}
				if (renderThis) {
					fieldsOutput += field.render();
				}
			}

		}

		output = output.replace('##FIELDS##', fieldsOutput);

		return output;

	}

	private virtual RyModel.ModelSchema generateModel() {
		RyModel.ModelSchema schema = new RyModel.ModelSchema();
		schema.sfObject = this.sfObject;
		if (this.action != null) {
			schema.action = this.action;
		}
		Boolean hasId = false;
		for (RyField field : this.fields) {
			if (field.sfField == null) {
				field.sfField = field.name;
			}
			if (field.sfField != null) {
				schema.addNode(field);
			}
			if (field.sfField == 'Id') {
				hasId = true;
			}
		}
		if (!hasId) {
			schema.addNode('Id');
		}
		return schema;
	}

}