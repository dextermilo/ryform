@isTest
public class RyFormParserTests {

	/* Tests */

	@isTest
	static void test_parse() {
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

		system.assert(form.get_field('first_name') != null);
		system.assert(form.get_field('bio') != null);
	}
}