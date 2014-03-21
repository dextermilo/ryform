public class RyWidget {
    
    public virtual class Base {
        
        public Set<String> cssClasses {
            get {
                if (cssClasses == null) {
                    cssClasses = new Set<String>{
                        'input-large',
                        'rywidget'
                    };
                }
                return cssClasses;
            }
            set;
        }

        public Set<String> validatorCss {
            Get {
                if (validatorCss == null) {
                    validatorCss = new Set<String>();
                }
                return validatorCss;
            }
            Set;
        }

        public String type;
        
        public RyField field;
        
        public RySubForm schema { Get; Set; }

        public List<String> values {
            get {
                if (values == null) {
                    values = new List<String>();
                }
                return values;
            }
            set;
        }

        // Get the value out of the parameters for this field
        public virtual String extract(Map<String, String> params) {
            
            if (params != null && params.size() > 0 && this.field.renderedName != null) {
                if (params.containsKey(this.field.renderedName)) {
                    return params.get(this.field.renderedName);
                }
            }
            return null;
            
        }

        public virtual void setup() {

        }
        
        // Convenience method to return either the current value or default value
        public virtual String renderValue() {
            return this.field.currentValue != null ? this.field.currentValue : this.field.defaultValue;
        }
        
        // Render the css classes for this widget, and validators
        public virtual String renderCssClasses() {
            String result = '';
            for (String cls : cssClasses) {
                result += cls + ' ';
            }
            for (String cls : validatorCss) {
                result += cls + ' ';
            }
            return result;
        }
        
        // Render
        public virtual String render() {
            return '<input type="text" class="'+ renderCssClasses() + '" name="'+this.field.renderedName+'" id="'+this.field.renderedName+'" value="' + renderValue() +'" />'+
                   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '') +
                   (this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '');
        }
        
    }
    
    /* Standard input widget */
    public class TextLine extends Base {
        
    }
    
    /* Textarea widget */
    public class Text extends Base {
        
        public override String render() {
            return (this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '')+'<textarea type="text" class="'+ renderCssClasses() + '" name="'+this.field.renderedName+'" id="'+this.field.renderedName+'">'+renderValue()+'</textarea>' +
                   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '') ;
        }
        
    }
    
    /* Checkbox widget */
    public class Checkbox extends Base {
        
        public override String render() {
            return '<label class="checkbox"><input type="checkbox" class="'+ renderCssClasses() + '" name="'+this.field.renderedName+'" id="'+this.field.renderedName+'" value="1"' + (renderValue() != '1' ? '' : 'checked="checked"') + '>'+(this.field.description != '' ? this.field.description : '')+'</label>' +
                   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '');
        }
        
    }

    /* Secret text widget */
    public class Secret extends Base {
        
        public override String render() {
            String rendered = super.render();
            // Change the widget to a password
            rendered = rendered.replace('type="text"', 'type="password"');
            // Remove the value on render
            rendered = rendered.replace('value="' + renderValue() +'"', '');
            return rendered;
        }
        
    }

    /* Plain Description widget */
    public class Plain extends Base {

        public override String extract(Map<String, String> params) {
            return '';
        }
        
        public override String render() {
            return '<p class="help-block help-description">'+this.field.description+'</p>';
        }
        
    }
    
    /* Password widget */
    public class Password extends Base {
        
        public override String renderValue() {
            return '';
        }
        
        public override String render() {
            return (this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '')+
                   '<input type="password" class="'+ renderCssClasses() + '" name="'+this.field.renderedName+'" id="'+this.field.renderedName+'" />'+
                   ('<br />') +
                   '<input type="password" equalto="#'+this.field.name+'" class="'+ renderCssClasses() + '" name="'+this.field.renderedName+'_confirm" id="'+this.field.renderedName+'_confirm" />'+
                   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '');
        }
        
    }
    
    /* Select Menu widget */
    public class SelectMenu extends Base {
        
        public override String render() {
            
            String output = '';
            
            output += '<select id="'+this.field.renderedName+'" name="'+this.field.renderedName+'" class="'+ renderCssClasses() + '">';
            
            for (String v : this.values) {
                
                output += '<option value="' + v + '"'+ (renderValue() == v ? ' selected="selected"' : '') +'>'+ v +'</option>';
                
            }
            
            output += '</select>';
            
            output += this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '';
            output += this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '';
            
            return output;
        }
        
    }

    /* Select Radio widget */
    public class SelectRadio extends Base {

        public override String render() {

            if (this.values == null || this.values.isEmpty()) {
                return '';
            }
            
            String output = '';
            
            for (String v : this.values) {
                
                output += '<label class="'+renderCssClasses()+' radio"><input type="radio" name="'+this.field.renderedName+'"  value="' + v + '"'+ (renderValue() == v ? ' checked="checked"' : '') +'/>'+ v +'</label>';
                
            }
            
            output += this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '';
            output += this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '';
            
            return output;
        }
        
    }

    /* Object list: use at your own peril */
    public class ObjectList extends Base {

        public override void setup() {
            if (this.schema != null) {
                this.schema.parentField = this.field;
                this.schema.setup();
            }
        }

        public override String extract(Map<String, String> params) {
            
            List<Map<String, String>> data = new List<Map<String, String>>();
            if (params != null && params.size() > 0 && this.schema != null) {

                List<String> keys = new List<String>();

                if (!this.schema.fields.isEmpty()) {
                    for (RyForm.Field field : this.schema.fields) {
                        for (String key : params.keySet()) {
                            if (key.startsWith(field.name) && key.contains('--')) {
                                keys.add(key);
                            }
                        }
                    }

                    keys.sort();

                    Integer i;
                    for (String key : keys) {
                        i = Integer.valueOf(key.substring(key.indexOf('--')+2, key.length()));
                        while (data.isEmpty() || data.size() < i) {
                            data.add(new Map<String,String>());
                        }
                        data[i-1].put(key, params.get(key));
                    }
                }

                return JSON.serialize(data);

            }
            return '';

        }

        public override String render() {

            String group_tmpl = '<div class="ryform-sub-group"><a class="close" href="#">x</a>##FIELDS##</div>';
            String output = (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '')+'<div class="well ryform-sub"><div class="ryform-sub-group hide"><a class="close" href="#">x</a>';

            if (this.schema != null) {
                for (RyField field : this.schema.fields) {
                    output += +field.render();
                }
            }

            output += '</div>';
            String val = this.renderValue();

            if (val != null && val != '') {

                if (val.contains('[')) {

                    List<Map<String,String>> data;

                    data = (List<Map<String,String>>)JSON.deserialize(val, List<Map<String,String>>.class);

                    if (!data.isEmpty()) {
                        Integer i = 1;
                        for (Map<String,String> dat : data) {
                            RySubForm tempSchema = this.schema;
                            tempSchema.suffix = String.valueOf(i);
                            tempSchema.params = dat;
                            tempSchema.setup();
                            output += group_tmpl.replace('##FIELDS##', tempSchema.render());
                            i++;
                        }
                    }
                }

            }

            output += '<a href="#" class="btn ryform-sub-add">Add</a></div>';
            return output;

        }

    }
    
}