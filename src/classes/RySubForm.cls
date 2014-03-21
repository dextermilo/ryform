public class RySubForm extends RyForm {

    public RyForm.Field parentField { get; set; }

    public String namespace {
        get {
            if (this.parentField != null) {
                return this.parentField.renderedName;
            }
            return '';
        }
    }

}