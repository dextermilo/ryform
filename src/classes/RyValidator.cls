public abstract class RyValidator {

    public virtual class Base {
        public String message;
        public Integer max;
        
        /* Return null means validation passed */
        public virtual String validate(Object value, Map<String, Object> params) {
            if (!this.check(value, params)) {
                return this.message;
            }
            return null;
        }

        public virtual Boolean check(Object value, Map<String, Object> params) {
            return true;
        }
        
        public virtual void setup() {
            
        }
    }
    
    /* Required Field */
    public virtual class Required extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value != null && value != '') {
                return true;
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'This field is required.';
        }
        
    }
    
    /* Is numeric */
    public virtual class isNumber extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value instanceOf Integer) {
                return true;
            } else {
                String strValue = String.valueOf(value);
                Pattern r = pattern.compile('^-?(?:\\d+|\\d{1,3}(?:,\\d{3})+)?(?:\\.\\d+)?$');
                Matcher m = r.matcher(strValue);
                return m.matches();
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid number';
        }
        
    }
    
    /* Is Email */
    public virtual class isEmail extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value instanceOf String) {
                Pattern r = pattern.compile('^[-a-z0-9~!$%^&*_=+}{\\\'?]+(\\.[-a-z0-9~!$%^&*_=+}{\\\'?]+)*@([a-z0-9_][-a-z0-9_]*(\\.[-a-z0-9_]+)*\\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}))(:[0-9]{1,5})?');
                Matcher m = r.matcher((String)value);
                return m.matches();
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid email address';
        }
        
    }
    
    /* Is URL */
    public virtual class isURL extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value instanceOf String) {
                String strValue = String.valueOf(value);
                Pattern r = pattern.compile('^(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]');
                Matcher m = r.matcher((String)value);
                return m.matches();
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid website URL';
        }
        
    }
    
    /* Max length */
    public virtual class maxLength extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value instanceOf String) {
                if (this.max != null) {
                    this.message = 'Please enter a value with less than '+String.valueOf(max) +' characters.';
                    return String.valueOf(value).length() <= max;
                } else {
                    return true;
                }
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = '';
        }
        
    }
    
    /* Is Date */
    public virtual class isDate extends Base {
        
        public override Boolean check(Object value, Map<String, Object> params) {
            if (value instanceOf Date) {
                return true;
            } else if (value instanceOf String) {
                if ((String)value != null && (String)value != '') {
                    try {
                        Date d = Date.parse((String)value);
                        return true;
                    } catch (exception e) {
                        return false;
                    }
                } else {
                    return true;
                }
            }
            return false;
        }
        
        public override void setup() {
            if (this.message == null) this.message = 'Please enter a valid date';
        }
        
    }
}