@isTest
public class RyFormTests {
    /* Tests */
    
    // helper
    private static RyForm setupTestForm() {
        RyForm form = new RyForm();
        
        RyForm.Field field = new RyForm.Field();
        field.name = 'spam';
        field.label = 'Test';
        field.description = 'A test field.';
        field.defaultValue = 'value';
        field.validator = 'isURL';
        field.max = 40;
        
        RyForm.Field field2 = new RyForm.Field();
        field2.name = 'number';
        field2.label = 'Number';
        field2.dataType = 'number';
        
        form.addField(field);
        form.addField(field2);
        
        Map<String, String> params = new Map<String, String>();
        params.put('spam', 'floogle');
        params.put('number', 'NaN');
        form.params = params;

        RyModel.ModelSchema model = new RyModel.ModelSchema();
        model.sfObject = 'Account';
        model.addNode('spam', new RySchema.Node('Name'));

        form.models.add(model);

        return form;
    }
    
    @isTest
    static void test_setup() {
        RyForm form = setupTestForm();
        
        form.setup();
        
        // Test Set current value
        system.assertEquals('floogle', form.fields[0].currentValue);
        
        // Test Setup validators
        Boolean req = false;
        Boolean num = false;
        Boolean man = false;
        
        for (RyForm.Field fld : form.fields) {
            for (RyValidator.Base v : fld.ryValidators) {
                if (v.cssClass == 'required') req = true;
                if (v.cssClass == 'number') num = true;
                if (v.cssClass == 'url') man = true;
            }
        }
        
        system.assert(req);
        system.assert(num);
        system.assert(man);
        
    }
    
    @isTest
    static void test_validate() {
        RyForm form = setupTestForm();
        
        form.setup();
        
        Boolean valid = form.validate();
        
        system.assert(!valid);
        system.assert(form.has_errors);
        
        form.params.put('spam', 'http://www.google.com');
        form.params.put('number', '100');
        
        form.setup();
        
        valid = form.validate();
        
        system.assert(valid);
        
    }
    
    @isTest
    static void test_getField() {
        RyForm form = setupTestForm();
        
        system.assert(form.getField('spam') != null);
    }

    @isTest
    static void test_addField() {
        RyForm form = setupTestForm();
        form.addField('count', 'The Count');

        system.assert(form.getField('count') != null);

    }

    @isTest
    static void test_render() {
        RyForm form = setupTestForm();
        system.assert(form.rendered.contains('spam') && form.rendered.contains('number'));
    }

    @isTest
    static void test_fieldsets() {
        RyForm form = setupTestForm();

        RyForm.Fieldset fieldset_no_name = new RyForm.Fieldset();
        fieldset_no_name.fields.add('number');

        form.fieldsets.add(fieldset_no_name);

        RyForm.Fieldset fieldset_with_name = new RyForm.Fieldset();
        fieldset_with_name.name = 'Food';
        fieldset_with_name.fields.add('spam');

        form.fieldsets.add(fieldset_with_name);

        form.fieldsets.add(new RyForm.Fieldset());

        form.setup();

        system.assert(form.rendered.contains('Food'));
        system.assert(form.rendered.indexOf('spam') > form.rendered.indexOf('number'));
    }

    @isTest
    static void test_process() {
        RyForm form = setupTestForm();

        form.setup();

        List<RyModel.ProcessedResponse> responses = form.process();

        system.assertEquals(null, responses);

        Map<String, String> params = new Map<String, String>();
        params.put('spam', 'http://www.google.com');
        params.put('number', '10');
        form.params = params;

        form.setup();

        responses = form.process();
        
        system.assert(responses[0].obj.Id != null);

    }

    @isTest
    static void test_auto_model() {

        RyForm form = new RyForm();
        form.sfObject = 'Account';
        form.auto_model = true;
        form.action = 'upsert';

        form.addField('Name', 'Name');
        form.addField('Description', 'Description');

        Map<String, String> params = new Map<String, String>{
            'Name' => 'ACME Sales',
            'Description' => 'A sales company'
        };

        form.params = params;

        form.setup();

        List<RyModel.ProcessedResponse> responses = form.process();

        system.assert(responses[0].success);
    }
}