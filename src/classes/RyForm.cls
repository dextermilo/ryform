public virtual class RyForm {

    public class Field extends RySchema.Node {
        public RyWidget.Base widget { get; set; }
        public String rendered {
            // This property simple returns the result of calling render()
            // which allows it to be used in VisualForce
            get {
                return render();
            }
            set;    
        }
        public String name {
            get {
                return key;
            }
            set {
                key = name;
            }
        }
        public String namespace { get; set; }
        public String suffix { get; set; }
        public String label { get; set; }
        public String description { get; set; }
        public String renderedName {
            // Add the namespace to the name
            get {
                String output = '';
                if (this.namespace != '' && this.namespace != null) {
                    output += this.namespace + '-' + this.name;
                } else {
                    output += this.name;
                }
                if (this.suffix != null && this.suffix != '') {
                    output += '--' + suffix;
                }
                return output;
            }
        }

        public override void setup() {
            // This is not done in the standard constructor because contructors are
            // not fired when the class is instantiated using JSON parser.
            if (this.required == null) this.required = true;
            super.setup();

            if (this.widget == null) this.widget = new RyWidget.TextLine();
            
            // TODO: this.widget.field = this;
            this.widget.setup();
        }
        
        public Field() {
            this.setup();
        }
        
        public String render() {
            return '<div class="form-group ryfield-'+this.renderedName+' '+(this.error != null && this.error != '' ? 'error' : '')+'"><label class="control-label" for="'+this.renderedName+'">'+this.label+(this.required ? '<span class="ryfield-required">*</span>' : '')+'</label><div class="controls">'+this.widget.render()+'</div></div>';
        }
        
        public override void setupValidators() {
            super.setupValidators();
            this.widget.validatorCss = null;
            
            for (RyValidator.Base validator : this.ryValidators) {
                if (validator.cssClass != null && validator.cssClass != '') {
                    this.widget.validatorCss.add(validator.cssClass);
                }
            }
        }

        public override String validate(Map<String, String> params) {
            if (this.currentValue == null) {
                this.currentValue = this.widget.extract(params);
            }
            return super.validate(params);
        }
        
        public void setupWidget() {
            // This method takes the non-functional base widget created when parsing
            // and converts it into the correct widget class.
            if (this.widget != null) {
                // Important: remove reference from widget to field to prevent recursive cycle
                this.widget.field = null;

                String widget_json = JSON.serialize(this.widget);
                JSONParser parser = JSON.createParser(widget_json);
                Type widget_class;
                if (!this.widget.type.contains('.')) {
                        widget_class = Type.forName('RyWidget.'+this.widget.type);
                }
                this.widget = (RyWidget.Base)parser.readValueAs(widget_class);
                this.widget.setup();
                // TODO: this.widget.field = this;
            }
        }
    }

    // Basic class for fieldsets
    public class Fieldset {
        public String name { get; set; }
        public List<String> fields { get; set; }

        public Fieldset() {
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
    public List<Fieldset> fieldsets { get; set; }
    
    // Map of parameters, i.e. raw form input values, that are passed into the form
    public Map<String, String> params { get; set; }
    
    // The list of fields on our form
    public List<RyForm.Field> fields { get; set; }
    
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
        if (fields == null) fields = new List<RyForm.Field>();
        if (errors == null) errors = new Map<String, String>();
        if (models == null) models = new List<RyModel.ModelSchema>();
        if (params == null) params = new Map<String, String>();
        if (fieldsets == null) fieldsets = new List<Fieldset>();
        if (namespace == null) namespace = '';
        if (suffix == null) suffix = '';
    }
    

    public virtual void addField(RyForm.Field field) {
        // Method to add a new field to the list. Prevents duplicate names.

        if (getField(field.name) == null) {
            fields.add(field);
        }
    }
    public virtual void addField(String name, String label) {
        // Method to create then add a field.

        RyForm.Field field = new RyForm.Field();
        field.name = name;
        field.label = label;
        addField(field);
    }
    
    
    public virtual RyForm.Field getField(String name) {
        // Method to get a field by name

        if (!fields.isEmpty()) {
            for (RyForm.Field field : fields) {
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
        
        for (RyForm.Field field : fields) {
            
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
        for (RyForm.Field field : fields) {
            
            String error = field.validate(this.params);

            if (error != null && error != '') {
                errors.put(field.name, error);
            }
            
        }
        
        for (RyForm.Field field : fields) {
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

            for (Fieldset fieldset : fieldsets) {

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
            
            for (RyForm.Field field : fields) {
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
        for (RyForm.Field field : this.fields) {
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