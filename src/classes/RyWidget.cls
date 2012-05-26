public with sharing class RyWidget {
	
	public virtual class Base {
		
		public set<String> css_classes {
			get {
				if (css_classes == null) {
					css_classes = new set<String>{
						'input-large'
					};
				}
				return css_classes;
			}
			set;
		}
		
		public string name;
		public string description;
		public string default_value;
		public string error;
		public string current_value;
		public string type;
		
		
		public virtual String extract(map<string,string> params) {
			
			if (params != null && params.size() > 0 && this.name != null) {
				if (params.containsKey(this.name)) {
					return params.get(this.name);
				}
			}
			return null;
			
		}
		
		public virtual String render_css_classes() {
			String result = '';
			for (String cls : css_classes) {
				result += cls + ' ';
			}
			return result;
		}
		
		public virtual String render() {
			return '<input type="text" class="'+ render_css_classes() + '" name="'+this.name+'" id="'+this.name+'" value="'+(this.current_value != null ? this.current_value : this.default_value)+'" />'+
				   (this.error != null ? '<p class="help-inline">'+this.error+'</p>' : '') +
				   (this.description != '' ? '<p class="help-block help-description">'+this.description+'</p>' : '');
		}
		
		public virtual String render(String name, String description, String default_value) {
			this.name = name;
			this.description = description;
			this.default_value = default_value;
			return render();
		}
		
		public virtual String render(String name, String description, String default_value, String error) {
			if (error != null && error != '') {
				this.error = error;
			}
			return render(name, description, default_value);
		}
		
	}
	
	/* Standard input widget */
	public class TextLine extends Base {
		
		
	}
	
	/* Textarea widget */
	public class Text extends Base {
		
		public override String render() {
			return '<p class="help-block">'+this.description+'</p><textarea type="text" class="input-large" name="'+this.name+'" id="'+this.name+'">'+this.default_value+'</textarea>' +
				   (this.error != null ? '<p class="help-inline">'+this.error+'</p>' : '');
		}
		
	}
	
}