*"* use this source file for your ABAP unit test classes

CLASS ltc_mass_ops_factory DEFINITION FINAL FOR TESTING DURATION LONG RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    METHODS:
      test_get_instance FOR TESTING.
ENDCLASS.

CLASS ltc_mass_ops_factory IMPLEMENTATION.

  METHOD test_get_instance.
    DATA(lo_object) = cl_mass_ops_factory=>get_mass_ops_cctr_instance( ).

    cl_abap_unit_assert=>assert_bound( act = lo_object
                                       msg = |Unable to instantiate class| ).
  ENDMETHOD.

ENDCLASS.
