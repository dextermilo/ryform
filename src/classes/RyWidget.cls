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
        
        public RyForm.Field field;

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
}