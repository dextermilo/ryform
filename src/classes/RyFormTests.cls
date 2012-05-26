@isTest
public class RyFormTests {
	/* Tests */
	
	// helper
	private static RyForm setupTestForm() {
		RyForm form = new RyForm();
		
		RyField field = new RyField();
		field.name = 'spam';
		field.label = 'Test';
		field.description = 'A test field.';
		field.default_value = 'value';
		field.validator = 'isURL';
		field.max = 40;
		
		RyField field2 = new RyField();
		field2.name = 'number';
		field2.label = 'Number';
		field2.data_type = 'number';
		
		form.add_field(field);
		form.add_field(field2);
		
		map<string,string> params = new map<string,string>();
		params.put('spam', 'floogle');
		params.put('number', 'NaN');
		form.params = params;

		RyModel.ModelSchema model = new RyModel.ModelSchema();
		model.sf_object = 'Account';
		model.addNode('spam', new RyModel.SchemaNode('Name'));

		form.models.add(model);

		return form;
	}
	
	@isTest
	static void test_setup() {
		RyForm form = setupTestForm();
		
		form.setup();
		
		// Test Set current value
		system.assertEquals('floogle', form.fields[0].current_value);
		
		// Test Setup validators
		Boolean req = false;
		Boolean num = false;
		Boolean man = false;
		
		for (RyField fld : form.fields) {
			for (RyValidator.Base v : fld.ryvalidators) {
				if (v.css_class == 'required') req = true;
				if (v.css_class == 'number') num = true;
				if (v.css_class == 'url') man = true;
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
	static void test_get_field() {
		RyForm form = setupTestForm();
		
		system.assert(form.get_field('spam') != null);
	}

	@isTest
	static void test_add_field() {
		RyForm form = setupTestForm();
		form.add_field('count', 'The Count');

		system.assert(form.get_field('count') != null);

	}

	@isTest
	static void test_render() {
		RyForm form = setupTestForm();
		system.assert(form.rendered.contains('spam') && form.rendered.contains('number'));
	}

	@isTest
	static void test_fieldsets() {
		RyForm form = setupTestForm();

		RyForm.RyFieldset fieldset_no_name = new RyForm.RyFieldset();
		fieldset_no_name.fields.add('number');

		form.fieldsets.add(fieldset_no_name);

		RyForm.RyFieldset fieldset_with_name = new RyForm.RyFieldset();
		fieldset_with_name.name = 'Food';
		fieldset_with_name.fields.add('spam');

		form.fieldsets.add(fieldset_with_name);

		form.fieldsets.add(new RyForm.RyFieldset());

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

		map<string,string> params = new map<string,string>();
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
		form.sf_object = 'Account';
		form.auto_model = true;
		form.action = 'upsert';

		form.add_field('Name', 'Name');
		form.add_field('Description', 'Description');

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