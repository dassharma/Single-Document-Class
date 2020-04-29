CLASS cl_mass_ops_factory DEFINITION PUBLIC FINAL CREATE PRIVATE .

  PUBLIC SECTION.
    CLASS-METHODS:
      get_mass_ops_cctr_instance RETURNING VALUE(ro_instance) TYPE REF TO if_mass_ops_cctr_handler.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-DATA: mo_instance TYPE REF TO cl_mass_ops_cctr_handler.
ENDCLASS.



CLASS CL_MASS_OPS_FACTORY IMPLEMENTATION.


  METHOD get_mass_ops_cctr_instance.
    IF mo_instance IS NOT BOUND.
      mo_instance = cl_mass_ops_cctr_handler=>create( ).
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.
ENDCLASS.
