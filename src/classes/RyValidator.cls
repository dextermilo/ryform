public abstract with sharing class RyValidator {
	
	public virtual class Base {
		
		public String message;
		public Boolean valid;
		public String css_class = '';
		
		public virtual void validate(String value, map<string,string> params) {
			this.valid = true;
		}
		
		public virtual void setup() {
			
		}
		
	}
	
	/* Required Field */
	public virtual class Required extends Base {
		
		public override void validate(String value, map<string,string> params) {
			this.valid = value != null && value != '';
		}
		
		public override void setup() {
			this.message = 'This field is required.';
			this.css_class = 'required';
		}
		
	}
	
	/* Is numeric */
	public virtual class isNumber extends Base {
		
		public override void validate(String value, map<string,string> params) {
			Pattern r = pattern.compile('^-?(?:\\d+|\\d{1,3}(?:,\\d{3})+)?(?:\\.\\d+)?$');
			Matcher m = r.matcher(value);
			this.valid = m.matches();
		}
		
		public override void setup() {
			this.message = 'Please enter a valid number';
			this.css_class = 'number';
		}
		
	}
	
	/* Is Email */
	public virtual class isEmail extends Base {
		
		public override void validate(String value, map<string,string> params) {
			Pattern r = pattern.compile('([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})');
			Matcher m = r.matcher(value);
			this.valid = m.matches();
		}
		
		public override void setup() {
			this.message = 'Please enter a valid email address';
			this.css_class = 'email';
		}
		
	}
	
	/* Is URL */
	public virtual class isURL extends Base {
		
		public override void validate(String value, map<string,string> params) {
			Pattern r = pattern.compile('^(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]');
			Matcher m = r.matcher(value);
			this.valid = m.matches();
		}
		
		public override void setup() {
			this.message = 'Please enter a valid website URL';
			this.css_class = 'url';
		}
		
	}
	
	/* Max length */
	public virtual class maxLength extends Base {
		
		public integer max;
		
		public override void validate(String value, map<string,string> params) {
			if (this.max != null) {
				this.message = 'Please enter a value with less than '+String.valueOf(max) +' characters.';
				this.valid = value.length() <= max;
			} else {
				this.valid = true;
			}
		}
		
		public override void setup() {
			this.message = '';
			this.css_class = '';
		}
		
	}
	
}