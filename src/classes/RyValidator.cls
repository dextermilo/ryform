public abstract class RyValidator {

	public virtual class Base {
		
		public String message;
		public Boolean valid;
		public String css_class = '';
		public integer max;
		
		public virtual void validate(String value, map<string,string> params) {
			this.valid = true;
		}

		public virtual void validate(String value) {
			this.validate(value, new Map<String,String>());
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
			Pattern r = pattern.compile('^[-a-z0-9~!$%^&*_=+}{\\\'?]+(\\.[-a-z0-9~!$%^&*_=+}{\\\'?]+)*@([a-z0-9_][-a-z0-9_]*(\\.[-a-z0-9_]+)*\\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}))(:[0-9]{1,5})?');
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
	
	/* Is Date */
	public virtual class isDate extends Base {
		
		public override void validate(String value, map<string,string> params) {
			if (value != null && value != '') {
				try {
					date d = date.parse(value);
					this.valid = true;
					
				} catch (exception e) {
					
					this.valid = false;
				}
			} else {
				this.valid = true;
			}
			
			/*
			Pattern r = pattern.compile('(0?[1-9]|[12][0-9]|3[01])(/|-)(0?[1-9]|1[012])(/|-)((19|20)\\d\\d)');
			Pattern iso = pattern.compile('((19|20)\\d\\d)(/|-)(0?[1-9]|1[012])(/|-)(0?[1-9]|[12][0-9]|3[01])');
			Matcher m = r.matcher(value);
			this.valid = m.matches();
			
			if (!this.valid) {
				Matcher n = iso.matcher(value);
				this.valid = n.matches();
			}
			*/
		}
		
		public override void setup() {
			this.message = 'Please enter a valid date';
			this.css_class = 'date';
		}
		
	}
}