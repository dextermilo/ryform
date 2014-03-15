public class RyField extends RyModel.SchemaNode {

    public RyWidget.Base widget { get; set; }
    
    // This property simple returns the result of calling render()
    // which allows it to be used in VisualForce
    public String rendered {
        get {
            return render();
        }
        set;    
    }

    // Add the namespace to the name
    public String renderedName {
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
    
    // This is not done in the standard constructor because contructors are
    // not fired when the class is instantiated using JSON parser.
    public override void setup() {
        if (this.required == null) this.required = true;
        super.setup();

        if (this.widget == null) this.widget = new RyWidget.TextLine();
        
        this.widget.field = this;
        this.widget.setup();
    }
    
    public RyField() {
        this.setup();
    }
    
    public String render() {
        
        return '<div class="control-group ryfield-'+this.renderedName+' '+(this.error != null && this.error != '' ? 'error' : '')+'"><label class="control-label" for="'+this.renderedName+'">'+this.label+(this.required ? '<span class="ryfield-required">*</span>' : '')+'</label><div class="controls">'+this.widget.render()+'</div></div>';
        
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
    
    // This method takes the non-functional base widget created when parsing
    // and converts it into the correct widget class.
    public void setupWidget() {
        
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
            this.widget.field = this;
        
        }
        
    }
    
}