RyForm is a form library written in apex to avoid VisualForce markup.

Refer to classes/RyFormReadmeTests.cls, also displayed below:

public class RyFormReadmeTest {
	
	/* This class provides tests and instructional comments for how to use
	 * RyForm from Apex.  Here, we will walk through defining a
	 * form, setting up widget and validation, and handling submissions.
	 */

	@isTest
	public static void basic_form() {

		/* RyForms are made up of a few core concepts:

			* RyForms: Holds the fields and most of the setup and initialization code for the form.
					   Everything starts here.

			* RyFields: Contains the information specific to a single field.  Name, label, description, widget, etc.

			* RyWidgets: The actual UI element that captures input from the user. For example, a checkbox or text field.

			* RyValidators: Take some input from a widget and make sure it meets some conditions. For example, is something
							an email address, website, number etc.


		   Forms can be defined two different ways:
		   		1) Imperatively through Apex code
		   		2) Parsed from JSON using RyFormParser

		   	We are going to start with creating a form through Apex.

		*/

		// Let's kick things off by instantiating our form:

		RyForm form = new RyForm();

		/* Our primary properties and attributes are now setup,
		   for now, we will only focus on the basics:

			fields = new List<RyField>();
				- Our fields

			errors = new Map<String, String>();
				- When there are validation errors, the error messages will be stored here keyed off of the field name. For example,
				  'email' => 'Please enter a valid email address.'

			params = new Map<String, String>();
				- The actual data submitted by the user/client. Usually, the first step to handling submissions is to set
				  form.params = ApexPages.currentPage().getParameters();

		*/

		// Because are form is brand new our field list will be empty:

		system.assert(form.fields.isEmpty());

		// Now we can instantiate a new RyField for adding to our form:

		RyField first_name = new RyField();

		// While we could add the field at this point, it won't be very useful without a name, label, or description:

		// The name is very important as it will be the used as the key to extract our field's value and validate it.

		first_name.name = 'first_name';

		// A label will be displayed next to the field on the form and represents the human friendly name for our field:

		first_name.label = 'First Name';

		/* Let's go ahead and add our field to the form, instead of operating on the list of fields directly we are going to use
		   the form.add_field(RyField) method.  This method will help us make sure everything is done correctly.
		   For example it will prevent us from adding two fields with the same name
		*/

		form.add_field(first_name);

		// Let's make sure the field was added:

		system.assert(form.fields.size() == 1);

		// We can now easily retrieve our field using the get_field(String) method. For example, we might use this to change
		// our field after it has been added, like by adding a description:

		form.get_field('first_name').description = 'This will be displayed below the widget on the form!';

		// Now that we have a field all we need to do is call form.setup() and we are good to go!

		// The setup() method is required by the from to setup lot's of important juicy bits, like validation.

		form.setup();

		// If this were a VisualForce page we could display the form on the page with {!form.rendered}
		// right now we will just assert that the form outputs our field:

		system.assert( form.rendered.contains('first_name') && form.rendered.contains('First Name') );

		// Okay, let's add another field.

		RyField email = new RyField();
		email.name = 'email';
		email.label = 'Email Address';

		// We want this to receive an email address from the user, so let's give it some validation:

		email.validator = 'isEmail';

		// And add it to the form:

		form.add_field(email);

		// Let's pass the form some input, the form always expects to receive the input as
		// a Map<String, String>

		Map<String, String> sample_input = new Map<String, String>();

		// Let's input values for our fields:

		sample_input.put('first_name', 'Ryan');
		sample_input.put('email', 'foo');

		// Okay! Into the form:

		form.params = sample_input;

		// Re-setup()

		form.setup();

		// Now let's run the form.validate() 
		
		Boolean success = form.validate();

		// But wait, we didn't submit a valid email address. So this should have failed validation:

		system.assert(!success);

		// (Notice that the validate method returns true when things pass and false when they don't)

		// It was probably the email field that failed, let's check the map of errors:

		system.assert(form.errors.containsKey('email'));

		// Yep, it was.  We can also get the error message off of the field itself:

		system.assert(form.get_field('email').error.contains('enter a valid email'));

		// We can also see that the error was rendered for the user:

		system.assert(form.rendered.contains('enter a valid email'));
		
		// Okay, let's correct our mistake and re-validate the form:

		sample_input.put('email', 'testemail@testdomain.com');

		form.params = sample_input;

		form.setup();

		success = form.validate();

		system.assert(success);

		// Yay success!  But wait, we have only added basic text line fields.
		// Let's add an optional bio field (and show off the alternate version of add_field(name, label):

		form.add_field('bio', 'Bio');
		form.get_field('bio').description = 'Optionally, say a little about yourself.';

		// Set the field.widget attribute (defaults to RyWidget.Textline), we want this field
		// to use a multiline textarea:

		form.get_field('bio').widget = new RyWidget.Text();

		// Fields also have field.setup() methods.  These help with creating the links
		// between field and widget and making sure that the field is in a stable state.
		// Normally, calling field.setup() is not required but it is a good idea after
		// setting a new widget.

		form.get_field('bio').setup();

		form.setup();

		// Let's make sure that the Text widget rendered:

		system.assert(form.rendered.contains('<textarea'));

		// Great! Now let's run validation again for good measure.

		success = form.validate();

		// Fail! It is saying that our bio field is required!

		system.assert(!success);

		system.assert(form.errors.get('bio').contains('required'));

		// No problem! Let's just change required attribute of our field (defaults to true):

		form.get_field('bio').required = false;

		form.setup();

		success = form.validate();

		system.assert(success);

		// Success!

	}

	/* Now that we have successfully created a basic form and done some validation
	   we can experiment with defining forms using JSON.
	*/

	@isTest
	public static void basic_json() {

		/* The RyFormParser is very handy when you want to persist an editable form schema in the
		   database or pass in a schema from an external system.

		   First let's create a string that represents the same form that we created
		   in the previous test.

		   I will try to make this pretty and easy to read, but the multiline formatting is
		   completely optional.  :)

		*/

		String schema = ' 															'+
		'{																			'+
		'    "fields": [			   												'+
		'		 {					   												'+
		'			 "name": "first_name",											'+
		'			 "label": "First Name"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "email",												'+
		'			 "label": "Email address",										'+
		'			 "validator": "isEmail"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "bio",													'+
		'			 "label": "Bio",												'+
		'			 "description": "Optionally, say a little about yourself.",		'+
		'			 "required": false,												'+
		'			 "widget": {													'+
		'			     "type": "Text"												'+
		'			 }																'+
		'		 }																	'+
		'	 ]																		'+
		'}																			';

		/* Mostly, this should look pretty much how you would expect.  However, notice
		   the  widget declaration on bio field.  Because of the way that the JSON
		   parser operates we have to instantiate each class initially as a RyWidget.Base,
		   however, there is magic built in to rebuild the widget using its "type"
		   attribute.

		   Want to use a widget class from a parent class other than RyWidget?
		   Just include the full dotted name like:

		   		"type": "AcmeWidgets.UberTextline"

		   	Now that we have our schema it is time to parse it:
		*/

		RyForm form = RyFormParser.parse(schema);

		// Verify that we got the fields:

		system.assertEquals(3, form.fields.size());

		system.assert(form.get_field('first_name') != null);

		system.assert(form.get_field('email') != null);

		system.assert(form.get_field('bio') != null);

		// Now we can use our form just like we did in the previous test:

		form.setup();

		// Check the output:

		system.assert(form.rendered.contains('<textarea'));

		// Done, that is all it takes to create the form from JSON!
	}

	/* One key part of making a form easy to read and useable is breaking it out into
	   multiple groups of fields or fieldsets.  RyForm allows for fieldsets to be
	   defined quite easily, and as we have seen, they are completely optional.
	*/

	@isTest
	public static void basic_fieldset() {
		/* Fieldsets are represented by a simple class, RyForm.RyFieldset, and are
		   stored on the form in a list.

		   Fieldsets can be defined through Apex or in JSON schemas.
		*/

		// Let's re-use the same schema we used in the last test.

		String schema = ' 															'+
		'{																			'+
		'    "fields": [			   												'+
		'		 {					   												'+
		'			 "name": "first_name",											'+
		'			 "label": "First Name"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "email",												'+
		'			 "label": "Email address",										'+
		'			 "validator": "isEmail"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "bio",													'+
		'			 "label": "Bio",												'+
		'			 "description": "Optionally, say a little about yourself.",		'+
		'			 "required": false,												'+
		'			 "widget": {													'+
		'			     "type": "Text"												'+
		'			 }																'+
		'		 }																	'+
		'	 ]																		'+
		'}																			';

		RyForm form = RyFormParser.parse(schema);

		// Now let's add a fieldset using Apex:

		RyForm.RyFieldset fieldset = new RyForm.RyFieldset();

		/*	RyFieldsets have two atributes:
				String name;
				List<String> fields;

			The fields list doesn't actually store RyFields but merely the keys to RyFields
			(their names).  Any fields that aren't added to a fieldset are just rendered 
			at the top of the form like they normally would.

			Setting a name will populate the <legend> of the fieldset and is completely optional.
		*/

		fieldset.name = 'Contact Information';
		fieldset.fields.add('email');

		// Now add the fieldset to the form:

		form.fieldsets.add(fieldset);

		// Setup the form and test the render!

		form.setup();

		system.assert(form.rendered.contains('<legend>Contact Information'));

		// And verify that the email field now appears after the Bio field:

		system.assert(form.rendered.indexOf('email') > form.rendered.indexOf('bio'));

		//  Success!

		// Now let's show how we could have done this using JSON:

		schema = ' 															'+
		'{																			'+
		'    "fields": [			   												'+
		'		 {					   												'+
		'			 "name": "first_name",											'+
		'			 "label": "First Name"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "email",												'+
		'			 "label": "Email address",										'+
		'			 "validator": "isEmail"											'+
		'		 },																	'+
		'		 {																	'+
		'			 "name": "bio",													'+
		'			 "label": "Bio",												'+
		'			 "description": "Optionally, say a little about yourself.",		'+
		'			 "required": false,												'+
		'			 "widget": {													'+
		'			     "type": "Text"												'+
		'			 }																'+
		'		 }																	'+
		'	 ],																		'+
		'	 "fieldsets": [															'+
		'		 {																	'+
		'			 "name": "Contact Information",									'+
		'			 "fields": [													'+
		'				 "email"													'+
		'			 ]																'+
		'		 }																	'+
		'	 ]																		'+
		'}																			';

		form = RyFormParser.parse(schema);

		form.setup();

		system.assert(form.rendered.contains('<legend>Contact Information'));

		// Success!

	}

	/*  RyForm also comes with some advanced magic built in: RyModel.  RyModel is a framework for
		handling input from multiple sources and turning it into SObjects. For example, you might
		have a Javascript application, form on an external website, or a RyForm which you want to 
		have perform validated upserts into Salesforce.

		Let's take a look at how it works with RyForm.
	*/

	@isTest
	public static void basic_model() {

		/*	Okay, let's say we want to create a form that inserts new Accounts.  We are going to
			insert our new Accounts with Names and Descriptions.
			
			First, let's setup our form.
		*/

		RyForm form = new RyForm();

		RyField name = new RyField();
		name.name = 'Name';
		name.label = 'Name';
		form.add_field(name);

		RyField description = new RyField();
		description.name = 'desc';
		description.label = 'Description';
		form.add_field(description);

		// Now, let's add a Model to our form:

		RyModel.ModelSchema model = new RyModel.ModelSchema();

		// Set the SObject that we are going to insert:

		model.sf_object = 'Account';

		// Add the fields we want to set:

		model.addNode(new RyModel.SchemaNode('Name'));

		/*	Now, in this case, the fields on our form could match the fields on the 
			SObject but sometimes it may not be trivial to have the field names exactly
			match the fields on the sobject, especially when you are using more than one
			model on a form.  In that case you can match the field on the sobject to
			a different field on the form like so:
		*/

		model.addNode('desc', new RyModel.SchemaNode('Description'));

		// Add the model to the form (notice that this is a list yes you can have multiple models
		// per form):

		form.models.add(model);

		// Okay, so now we can setup the form, pass in some input, and send it off to
		// RyModel.processModel() to dynamically insert the SObject.

		Map<String, String> form_input = new Map<String, String>{
			'Name' => 'Acme Publishing',
			'desc' => 'Acme Publishing publishes books!'
		};

		form.params = form_input;

		form.setup();

		// Process the model!

		List<RyModel.ProcessedResponse> responses = form.process();

		// Do we think it worked?

		system.assert(responses[0].success);

		// Yep!  But let's make sure:

		Account acme = [SELECT Id, Name, Description FROM Account WHERE Id = :responses[0].obj.Id];

		// Verify we set the right fields to the correct values:

		system.assertEquals(acme.Name, form_input.get('Name'));
		system.assertEquals(acme.Description, form_input.get('desc'));

		// Rocking! We just magically created a new Account!

		/*	RyModel.ProcessedResponse objects have three attributes:

				sObject obj - The sObject that was created.

				Boolean success - Whether or not the process succeeded.

				String error - If there was a failure, this will hold the exception message.

		*/
	}

	/* 	In many cases you won't be working on only one sObject, for example, when dealing
		with CampaignMembers and Contacts.

		Let's go over an example of how we might handle creating multiple objects using models
		and custom processing.
	*/

}