public class RyFormParser {

    public static RyForm parse(String schema) {

        JSONParser parser = JSON.createParser(schema);
        Type formClass =  Type.forName('RyForm');
        Ryform form = (RyForm)parser.readValueAs(formClass);

        if (form.fields != null) {
            for (RyForm.Field field : form.fields) {
                field.setupWidget();
                field.setup();
            }
        }

        form.setDefaults();
        
        return form;

    }
    
    
}