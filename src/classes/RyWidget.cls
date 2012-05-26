public class RyWidget {
	
	public virtual class Base {
		
		public set<String> css_classes {
			get {
				if (css_classes == null) {
					css_classes = new set<String>{
						'input-large',
						'rywidget'
					};
				}
				return css_classes;
			}
			set;
		}

		public set<String> validator_css {
			Get {
				if (validator_css == null) {
					validator_css = new set<String>();
				}
				return validator_css;
			}
			Set;
		}

		public string type;
		
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
		public virtual String extract(map<string,string> params) {
			
			if (params != null && params.size() > 0 && this.field.rendered_name != null) {
				if (params.containsKey(this.field.rendered_name)) {
					return params.get(this.field.rendered_name);
				}
			}
			return null;
			
		}

		public virtual void setup() {

		}
		
		// Convenience method to return either the current value or default value
		public virtual String render_value() {
			return this.field.current_value != null ? this.field.current_value : this.field.default_value;
		}
		
		// Render the css classes for this widget, and validators
		public virtual String render_css_classes() {
			String result = '';
			for (String cls : css_classes) {
				result += cls + ' ';
			}
			for (String cls : validator_css) {
				result += cls + ' ';
			}
			return result;
		}
		
		// Render
		public virtual String render() {
			return '<input type="text" class="'+ render_css_classes() + '" name="'+this.field.rendered_name+'" id="'+this.field.rendered_name+'" value="' + render_value() +'" />'+
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
			return (this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '')+'<textarea type="text" class="'+ render_css_classes() + '" name="'+this.field.rendered_name+'" id="'+this.field.rendered_name+'">'+render_value()+'</textarea>' +
				   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '') ;
		}
		
	}
	
	/* Checkbox widget */
	public class Checkbox extends Base {
		
		public override String render() {
			return '<label class="checkbox"><input type="checkbox" class="'+ render_css_classes() + '" name="'+this.field.rendered_name+'" id="'+this.field.rendered_name+'" value="1"' + (render_value() != '1' ? '' : 'checked="checked"') + '>'+(this.field.description != '' ? this.field.description : '')+'</label>' +
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
			rendered = rendered.replace('value="' + render_value() +'"', '');
			return rendered;
		}
		
	}

	/* Plain Description widget */
	public class Plain extends Base {

		public override String extract(map<string,string> params) {
			return '';
		}
		
		public override String render() {
			return '<p class="help-block help-description">'+this.field.description+'</p>';
		}
		
	}
	
	/* Password widget */
	public class Password extends Base {
		
		public override String render_value() {
			return '';
		}
		
		public override String render() {
			return (this.field.description != '' ? '<p class="help-block help-description">'+this.field.description+'</p>' : '')+
				   '<input type="password" class="'+ render_css_classes() + '" name="'+this.field.rendered_name+'" id="'+this.field.rendered_name+'" />'+
				   ('<br />') +
				   '<input type="password" equalto="#'+this.field.name+'" class="'+ render_css_classes() + '" name="'+this.field.rendered_name+'_confirm" id="'+this.field.rendered_name+'_confirm" />'+
				   (this.field.error != null ? '<p class="help-inline">'+this.field.error+'</p>' : '');
		}
		
	}
	
	/* Select Menu widget */
	public class SelectMenu extends Base {
		
		public override String render() {
			
			String output = '';
			
			output += '<select id="'+this.field.rendered_name+'" name="'+this.field.rendered_name+'" class="'+ render_css_classes() + '">';
			
			for (String v : this.values) {
				
				output += '<option value="' + v + '"'+ (render_value() == v ? ' selected="selected"' : '') +'>'+ v +'</option>';
				
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
				
				output += '<label class="'+render_css_classes()+' radio"><input type="radio" name="'+this.field.rendered_name+'"  value="' + v + '"'+ (render_value() == v ? ' checked="checked"' : '') +'/>'+ v +'</label>';
				
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
				this.schema.parent_field = this.field;
				this.schema.setup();
			}
		}

		public override String extract(map<string,string> params) {
			
			List<Map<String, String>> data = new List<Map<String, String>>();
			if (params != null && params.size() > 0 && this.schema != null) {

				List<String> keys = new List<String>();

				if (!this.schema.fields.isEmpty()) {
					for (RyField field : this.schema.fields) {
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
			String val = this.render_value();

			if (val != null && val != '') {

				if (val.contains('[')) {

					List<Map<String,String>> data;

					data = (List<Map<String,String>>)JSON.deserialize(val, List<Map<String,String>>.class);

					if (!data.isEmpty()) {
						Integer i = 1;
						for (Map<String,String> dat : data) {
							RySubForm temp_schema = this.schema;
							temp_schema.suffix = String.valueOf(i);
							temp_schema.params = dat;
							temp_schema.setup();
							output += group_tmpl.replace('##FIELDS##', temp_schema.render());
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