public class RySubForm extends RyForm {

	public RyField parent_field { get; set; }

	public String namespace {
		get {
			if (this.parent_field != null) {
				return this.parent_field.rendered_name;
			}
			return '';
		}
	}

}