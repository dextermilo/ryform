public abstract class RyValidator {

    public virtual class Base {
        public String message;
        public integer max;
        
        public virtual Boolean validate(String value, Map<String, String> params) {
            return true;
        }

        public virtual Boolean validate(String value) {
            return this.validate(value, new Map<String,String>());
        }
        
        public virtual void setup() {
            
        }
    }
    
    /* Required Field */
    public virtual class Required extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            return value != null && value != '';
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'This field is required.';
        }
        
    }
    
    /* Is numeric */
    public virtual class isNumber extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            Pattern r = pattern.compile('^-?(?:\\d+|\\d{1,3}(?:,\\d{3})+)?(?:\\.\\d+)?$');
            Matcher m = r.matcher(value);
            return m.matches();
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid number';
        }
        
    }
    
    /* Is Email */
    public virtual class isEmail extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            Pattern r = pattern.compile('^[-a-z0-9~!$%^&*_=+}{\\\'?]+(\\.[-a-z0-9~!$%^&*_=+}{\\\'?]+)*@([a-z0-9_][-a-z0-9_]*(\\.[-a-z0-9_]+)*\\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}))(:[0-9]{1,5})?');
            Matcher m = r.matcher(value);
            return m.matches();
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid email address';
        }
        
    }
    
    /* Is URL */
    public virtual class isURL extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            Pattern r = pattern.compile('^(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]');
            Matcher m = r.matcher(value);
            return m.matches();
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid website URL';
        }
        
    }
    
    /* Max length */
    public virtual class maxLength extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            if (this.max != null) {
                if (this.message == null) this.message = 'Please enter a value with less than '+String.valueOf(max) +' characters.';
                return value.length() <= max;
            } else {
                return true;
            }
        }
        
        public override void setup() {
            if (this.message == null) this.message = '';
        }
        
    }
    
    /* Is Date */
    public virtual class isDate extends Base {
        
        public override Boolean validate(String value, Map<String, String> params) {
            if (value != null && value != '') {
                try {
                    date d = date.parse(value);
                    return true;
                    
                } catch (exception e) {
                    
                    return false;
                }
            } else {
                return true;
            }
            
            /*
            Pattern r = pattern.compile('(0?[1-9]|[12][0-9]|3[01])(/|-)(0?[1-9]|1[012])(/|-)((19|20)\\d\\d)');
            Pattern iso = pattern.compile('((19|20)\\d\\d)(/|-)(0?[1-9]|1[012])(/|-)(0?[1-9]|[12][0-9]|3[01])');
            Matcher m = r.matcher(value);
            return m.matches();
            
            if (!this.valid) {
                Matcher n = iso.matcher(value);
                return n.matches();
            }
            */
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid date';
        }
        
    }
}