public abstract class RySchema {

    // Map of validators that should automatically be applied to fields of a certain type
    public static Map<String, List<String>> dataTypeValidators {
        get {
            if (dataTypeValidators == null) {
                dataTypeValidators = new Map<String, List<String>>();
                dataTypeValidators.put('number', new List<String>{'isNumber'});
                dataTypeValidators.put('integer', new List<String>{'isNumber'});
                dataTypeValidators.put('url', new List<String>{'isURL'});
                dataTypeValidators.put('email', new List<String>{'isEmail'});
                dataTypeValidators.put('date', new List<String>{'isDate'});
            }
            return dataTypeValidators;
        }
    }

    /* This class is used to represent each field/attribute */
    public virtual class Node {
        
        public String sfObject;
        public String sfField;
        public String key { get; set; }
        public String suffix { get; set; }
        public String dataType { 
            get {
                if (sfObject != null && sfField != null && dataTypeFormSf == true) {
                    return autoDataType;
                }
                return dataType;
            }
            set;
        }
        public Boolean dataTypeFormSf { get; set; } // Assign data type from sfField definition
        private String autoDataType {
            get {
                if (sfObject != null && sfField != null) {
                    autoDataType = RyModel.castField(sfField, sfObject);
                } else {
                    autoDataType = null;
                }
                return autoDataType;
            }
            set;
        }
        
        public Boolean required { get; set; }
        public String defaultValue { get; set; }
        public String currentValue { get; set; }
        public Boolean autoValidate { get; set; } // Automatically assign validator from sObject
        public String validator { get; set; } // Allows for adding of a single validator by String lookup
        public List<String> validators { get; set; } // Allows for adding of multiple validators by List of strings
        public List<RyValidator.Base> ryValidators { get; set; } // Instanciated validator classes are added to this list
        public String error { get; set; } // The error message if any associated with this field
        public Integer max { get; set; } // Rules (length for text fields, values for numbers)
        
        public virtual void setup() {
            // This is not done in the standard constructor because contructors are
            // not fired when the class is instantiated using JSON parser.
            if (this.key == null) this.key = '';
            if (this.dataType == null) this.dataType = 'text';
            if (this.required == null) this.required = false;
            if (this.dataTypeFormSf == null) {
                if (this.sfField != null && this.sfObject != null) {
                    this.dataTypeFormSf = true;
                } else {
                    this.dataTypeFormSf = false;
                }
            }
            if (this.defaultValue == null) this.defaultValue = '';
            if (this.validator == null) this.validator = '';
            if (this.validators == null) this.validators = new List<String>();
            if (this.error == null) this.error = '';
        }
        
        public Node() {
            setup();
        }
        
        public Node(String sfField) {
            this.sfField = sfField;
            setup();
        }

        public Node(String name, String sfField) {
            this.key = key;
            this.sfField = sfField;
        }

        public virtual String validate(Map<String, String> params) {
            for (RyValidator.Base validator : this.ryValidators) {
                // Run validator
                validator.validate(this.currentValue, params);
                if (!validator.valid) {
                    this.error = validator.message;
                    return this.error;
                }
                    
            }
            return '';
        }

        public virtual String validate() {
            return this.validate(new Map<String, String>());
        }

        public virtual void addValidator(String validator) {
            if (validator != null) {
                this.validators.add(validator);
            }
        }

        public virtual void setupValidators() {
            Set<string> validatorSet = new Set<String>();
            validatorSet.addAll(this.validators);
            
            //  - Required fields
            if (this.required) {
                validatorSet.add('Required');
            }
            
            //  - For data types
            if (this.dataType != null) {
                if (RySchema.dataTypeValidators.containsKey(this.dataType)) {
                    validatorSet.addAll(RySchema.dataTypeValidators.get(this.dataType));
                }
            }
            
            //  - Manually added
            if (this.validator != null && this.validator != '') {
                validatorSet.add(this.validator);
            }
            
            //  - Max Length
            if (this.max > 0) {
                validatorSet.add('maxLength');
            }
            
            this.validators = new List<String>();
            this.ryValidators = new List<RyValidator.Base>();
            
            for (String vString : validatorSet) {
                JSONParser parser = JSON.createParser('{}');
                Type vClass;
                if (!vString.contains('.')) {
                    vClass = Type.forName('RyValidator.'+vString);
                }
                RyValidator.Base validator = (RyValidator.Base)parser.readValueAs(vClass);
                if (this.max > 0) {
                    validator.max = this.max;
                }
                validator.setup();
                this.ryValidators.add(validator);
            }
        }
    }

	public RySchema() {
		
	}
}