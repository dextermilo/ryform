public class RyFormParser {

	public static RyForm parse(String schema) {

		JSONParser parser = JSON.createParser(schema);
		Type form_class =  Type.forName('RyForm');
        Ryform form = (RyForm)parser.readValueAs(form_class);

        if (form.fields != null) {
        	for (RyField field : form.fields) {
        		field.widgetify();
        		field.setup();
        	}
        }

        form.set_defaults();
        
        return form;

	}
	
	
}