@isTest
public class RyWidgetTests {
	/* Tests */
	@isTest
	static void test_base() {
		
		// Create a field, this is required for the widget
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		// Create a widget, relate it to the field
		RyWidget.Base w = new RyWidget.Base();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		// Render the widget and assert the markup contains the variables.
		rendered = w.render();
		
		system.assert(rendered.contains(f.name));
		system.assert(rendered.contains(f.description));
		system.assert(rendered.contains(f.defaultValue));
		system.assert(rendered.contains('input-large'));
		
		// Set a current value and test that it is displayed
		f.currentValue = 'test input';
		rendered = w.render();
		system.assert(rendered.contains(f.currentValue));
		system.assert(!rendered.contains(f.defaultValue));
		
		// Add error
		f.error = 'Test error.';
		rendered = w.render();
		system.assert(rendered.contains(f.error));
		
		// Extract the value
		Map<String, String> params = new Map<String, String>();
		params.put('test', 'monkey');
		
		system.assertEquals(null, w.extract(null));
		system.assertEquals('monkey', w.extract(params));
		
	}
	
	@isTest
	static void test_text() {
		
		// Create a field, this is required for the widget
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		// Create a Text Widget, relate it to the field
		RyWidget.Text w = new RyWidget.Text();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();
		
		// Most of this class is covered in the RyWidget.Base test. So in this case we just need to make sure
		// that we rendered different markup.
		system.assert(rendered.contains('<textarea'));
		
	}
	
	@isTest
	static void test_checkbox() {
		
		// Create a field, this is required for the widget
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';	
		
		RyWidget.Checkbox w = new RyWidget.Checkbox();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();
		
		f.error = 'Test error.';
		rendered = w.render();
		system.assert(!rendered.contains('checked'));
		system.assert(rendered.contains(f.error));
		system.assert(rendered.contains('checkbox'));
		f.currentValue = '1';
		rendered = w.render();
		system.assert(rendered.contains('checked'));
	}
	
	@isTest
	static void test_password() {
		
		// Create a field, this is required for the widget
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';	
		
		RyWidget.Password w = new RyWidget.Password();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();
		
		f.error = 'Test error.';
		rendered = w.render();
		system.assert(rendered.contains(f.error));
		system.assert(rendered.contains('password'));
		system.assertEquals(w.renderValue(), '');
	}
	
	@isTest
	static void test_selectMenu() {
		
		// Create a field, this is required for the widget
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		RyWidget.SelectMenu w = new RyWidget.SelectMenu();
		w.values = new List<String>{
			'Dog',
			'Cat',
			'Goose'
		};
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();
		
		for (String v : w.values) {
			system.assert(rendered.contains(v));
		}
		system.assert(rendered.contains('select'));
	}

	@isTest
	static void test_secret() {
		
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		RyWidget.Secret w = new RyWidget.Secret();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();

		system.assert(rendered.contains('type="password"'));
		
	}

	@isTest
	static void test_plain() {
		
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		RyWidget.Plain w = new RyWidget.Plain();
		f.widget = w;
		w.field = f;
		
		String rendered;
		
		rendered = w.render();

		system.assert(!rendered.contains('<input'));
		system.assertEquals('', w.extract(new Map<String, String>()));
	}

	@isTest
	static void test_objectlist() {
		
		RyField f = new RyField();
		f.name = 'test';
		f.description = 'This is a test.';
		f.defaultValue = 'test value';
		
		RyWidget.ObjectList w = new RyWidget.ObjectList();
		f.widget = w;
		w.field = f;

		// Subform Schema
		RySubForm subform = new RySubForm();

		subform.addField('f1', 'Field1');
		subform.addField('f2', 'Field2');
		subform.parentField = f;

		w.schema = subform;
		w.setup();
		f.setup();
		
		String rendered;
		
		rendered = w.render();
		
		system.assert(rendered.contains('f1'));
		system.assert(rendered.contains('f2'));
		
		// Pass in some data
		Map<String, String> params = new Map<String, String>();

		params.put('f1--1', 'vf1-1');
		params.put('f2--1', 'vf2-1');

		params.put('f1--2', 'vf1-2');
		params.put('f2--2', 'vf2-2');

		system.assertEquals('', w.extract(null));

		String raw_val = w.extract(params);
		
		List<Map<String, String>> val = (List<Map<String, String>>)JSON.deserialize(raw_val, List<Map<String, String>>.class);

		system.assertEquals('vf1-1', val[0].get('f1--1'));
		system.assertEquals('vf2-1', val[0].get('f2--1'));

		system.assertEquals('vf1-2', val[1].get('f1--2'));
		system.assertEquals('vf2-2', val[1].get('f2--2'));

		f.currentValue = raw_val;

		system.assert(w.render().contains('vf1-1'));
		system.assert(w.render().contains('vf2-2'));

	}
}