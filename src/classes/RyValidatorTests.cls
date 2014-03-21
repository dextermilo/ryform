@isTest
public class RyValidatorTests {
    /* Tests */
    
    public class Mock {
        String name = 'Foozy';
    }

    @isTest
    static void test_base() {
        RyValidator.Base v = new RyValidator.Base();
        
        Map<String, String> params = new Map<String, String>();
        
        v.setup();
        String error = v.validate('value', params);
        system.assertEquals(error, null);
    }
    
    @isTest
    static void test_required() {
        RyValidator.Required v = new RyValidator.Required();
        Map<String, String> params = new Map<String, String>();
        v.setup();
        
        // Validate with no value, fail
        String error = v.validate('', params);
        system.assertNotEquals(error, null);
        
        // Validate with a value, pass
        error = v.validate('value', params);
        system.assertEquals(error, null);
    }
    
    @isTest
    static void test_number() {
        RyValidator.isNumber v = new RyValidator.isNumber();
        Map<String, String> params = new Map<String, String>();
        v.setup();
        
        // Validate with non-number, fail
        String error = v.validate('abc', params);
        system.assertNotEquals(error, null);
        
        // Validate with a number, pass
        error = v.validate('23', params);
        system.assertEquals(error, null);
    }
    
    @isTest
    static void test_email() {
        RyValidator.isEmail v = new RyValidator.isEmail();
        
        Map<String, String> params = new Map<String, String>();
        
        v.setup();
        
        // Validate with non-email, fail
        String error = v.validate('abc@cba@bogus.com', params);
        
        system.assertNotEquals(error, null);
        
        // Validate with an email, pass
        error = v.validate('testmoney+123@gmail.com', params);
        system.assertEquals(error, null);
    }
    
    @isTest
    static void test_date() {
        RyValidator.isDate v = new RyValidator.isDate();
        
        Map<String, String> params = new Map<String, String>();
        
        v.setup();
        
        //Validate with slashes, pass
        String error = v.validate('5/5/2000', params);
        system.assertEquals(error, null);
        
        //Validate with dashes, fail
        error = v.validate('5-5-2000', params);
        system.assertNotEquals(error, null);
        
        //Validate with yyyy/mm/dd format, fail
        error = v.validate('2000-5-5', params);
        system.assertNotEquals(error, null);
        
        //Validate with bad month value, yyyy/mm/dd, fail
        error = v.validate('2000-30-5', params);
        system.assertNotEquals(error, null);
        
        //Validate with chars, fail
        error = v.validate('THIS IS NOT A DATE', params);
        system.assertNotEquals(error, null);
        
        //Validate with dd/yyyy/mm, fail
        error = v.validate('5-2000-5', params);
        system.assertNotEquals(error, null);
        
        //Validate with excessive values for month, fail
        error = v.validate('50-5-2000', params);
        system.assertNotEquals(error, null);
        
        //Validate with excessive values for day, fail
        error = v.validate('5-50-2000', params);
        system.assertNotEquals(error, null);
        
        //Validate with excessive values for year, fail
        error = v.validate('5-5-20000', params);
        system.assertNotEquals(error, null);
        
        //Validate with abbreviated year, fail
        error = v.validate('5-5-12', params);
        system.assertNotEquals(error, null);

        // Validate with wrong class
        error = v.validate(new Mock(), params);
        system.assertNotEquals(null, error);
    }
        
    
    
    @isTest
    static void test_url() {
        RyValidator.isURL v = new RyValidator.isURL();
        
        Map<String, String> params = new Map<String, String>();
        
        v.setup();
        
        // fail
        String error = v.validate('funny.nothing', params);
        system.assertNotEquals(error, null);
        
        // pass
        error = v.validate('http://www.google.com', params);
        system.assertEquals(error, null);
    }
    
    @isTest
    static void test_maxLength() {
        RyValidator.maxLength v = new RyValidator.maxLength();
        Map<String, String> params = new Map<String, String>();
        v.setup();
        // Validate without max set, pass
        v.max = null;
        String error = v.validate('12345678901', params);
        system.assertEquals(error, null);
        
        v.max = 10;
        
        // fail
        error = v.validate('12345678901', params);
        
        system.assertNotEquals(error, null);
        system.assert(error.contains(String.valueOf(v.max)));
        
        // pass
        error = v.validate('123', params);
        system.assertEquals(error, null);
    }
}