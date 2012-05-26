@isTest
public class RyValidatorTests {
	/* Tests */
	

	@isTest
	static void test_base() {
		RyValidator.Base v = new RyValidator.Base();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		v.validate('value', params);
		
		system.assert(v.valid);
	}
	
	@isTest
	static void test_required() {
		RyValidator.Required v = new RyValidator.Required();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		
		// Validate with no value, fail
		v.validate('', params);
		
		system.assert(!v.valid);
		
		// Validate with a value, pass
		v.validate('value', params);
		
		system.assert(v.valid);
	}
	
	@isTest
	static void test_number() {
		RyValidator.isNumber v = new RyValidator.isNumber();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		
		// Validate with non-number, fail
		v.validate('abc', params);
		
		system.assert(!v.valid);
		
		// Validate with a number, pass
		v.validate('23', params);
		
		system.assert(v.valid);
	}
	
	@isTest
	static void test_email() {
		RyValidator.isEmail v = new RyValidator.isEmail();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		
		// Validate with non-email, fail
		v.validate('abc@cba@bogus.com', params);
		
		system.assert(!v.valid);
		
		// Validate with an email, pass
		v.validate('testmoney+123@gmail.com', params);
		
		system.assert(v.valid);
	}
	
	@isTest
	static void test_date() {
		RyValidator.isDate v = new RyValidator.isDate();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		
		//Validate with slashes, pass
		v.validate('5/5/2000', params);
		
		system.assert(v.valid);
		
		//Validate with dashes, fail
		v.validate('5-5-2000', params);
		
		system.assert(!v.valid);
		
		//Validate with yyyy/mm/dd format, fail
		v.validate('2000-5-5', params);
		
		system.assert(!v.valid);
		
		//Validate with bad month value, yyyy/mm/dd, fail
		v.validate('2000-30-5', params);
		
		system.assert(!v.valid);
		
		//Validate with chars, fail
		v.validate('THIS IS NOT A DATE', params);
	
		system.assert(!v.valid);
		
		//Validate with dd/yyyy/mm, fail
		v.validate('5-2000-5', params);
		
		system.assert(!v.valid);
		
		//Validate with excessive values for month, fail
		v.validate('50-5-2000', params);
		
		system.assert(!v.valid);
		
		//Validate with excessive values for day, fail
		v.validate('5-50-2000', params);
		
		system.assert(!v.valid);
		
		//Validate with excessive values for year, fail
		v.validate('5-5-20000', params);
		
		system.assert(!v.valid);
		
		//Validate with abbreviated year, fail
		v.validate('5-5-12', params);
		
		system.assert(!v.valid);
				
	}
		
	
	
	@isTest
	static void test_url() {
		RyValidator.isURL v = new RyValidator.isURL();
		
		map<string,string> params = new map<string,string>();
		
		v.setup();
		
		// fail
		v.validate('funny.nothing', params);
		
		system.assert(!v.valid);
		
		// pass
		v.validate('http://www.google.com', params);
		
		system.assert(v.valid);
	}
	
	@isTest
	static void test_maxLength() {
		RyValidator.maxLength v = new RyValidator.maxLength();
		
		map<string,string> params = new map<string,string>();
		
		// Validate without max set, pass
		v.max = null;
		v.validate('12345678901', params);
		system.assert(v.valid);
		
		v.max = 10;
		v.setup();
		
		// fail
		v.validate('12345678901', params);
		
		system.assert(!v.valid);
		system.assert(v.message.contains(String.valueOf(v.max)));
		
		// pass
		v.validate('123', params);
		
		system.assert(v.valid);
	}
}