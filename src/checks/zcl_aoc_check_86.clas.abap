CLASS zcl_aoc_check_86 DEFINITION
  PUBLIC
  INHERITING FROM zcl_aoc_super_root
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS constructor .

    METHODS get_message_text
         REDEFINITION .
    METHODS run
         REDEFINITION .
    METHODS consolidate_for_display
         REDEFINITION .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_AOC_CHECK_86 IMPLEMENTATION.


  METHOD consolidate_for_display.

    DATA: ls_result LIKE LINE OF p_results,
          lv_index  TYPE i.

    super->consolidate_for_display(
      EXPORTING
        p_sort_by_user    = p_sort_by_user
        p_sort_by_package = p_sort_by_package
        p_sort_by_object  = p_sort_by_object
      CHANGING
        p_results         = p_results
        p_results_hd      = p_results_hd ).

    READ TABLE p_results INTO ls_result WITH KEY test = myname.
    IF sy-subrc = 0 AND ls_result-code = '002'.
* only keep one result if the database is not uploaded
      lv_index = sy-tabix + 1.
      DELETE p_results FROM lv_index WHERE test = myname.
    ENDIF.

  ENDMETHOD.


  METHOD constructor.

    super->constructor( ).

    version  = '001'.
    position = '086'.

    has_documentation = c_true.
    has_attributes = abap_true.
    attributes_ok  = abap_true.
    has_display_consolidation = abap_true.

    mv_errty = c_error.

    add_obj_type( c_type_program ).
    add_obj_type( 'DOMA' ).
    add_obj_type( 'DTEL' ).
    add_obj_type( 'TABL' ).
    add_obj_type( 'VIEW' ).
    add_obj_type( 'TTYP' ).
    add_obj_type( 'SHLP' ).
    add_obj_type( 'WAPA' ).

  ENDMETHOD.


  METHOD get_message_text.

    CLEAR p_text.

    CASE p_code.
      WHEN '001'.
        p_text = 'Uses &1 &2, see note &3'.                 "#EC NOTEXT
      WHEN '002'.
        p_text = 'Load database via report ZAOC_UPLOAD_SIDB'. "#EC NOTEXT
      WHEN OTHERS.
        super->get_message_text( EXPORTING p_test = p_test
                                           p_code = p_code
                                 IMPORTING p_text = p_text ).
    ENDCASE.

  ENDMETHOD.


  METHOD run.

* abapOpenChecks
* https://github.com/larshp/abapOpenChecks
* MIT License

    DATA: lv_obj_type    TYPE euobj-id,
          lt_result      TYPE STANDARD TABLE OF zaoc_sidb,
          ls_result      LIKE LINE OF lt_result,
          lv_note        TYPE string,
          ls_sidb        TYPE zaoc_sidb,
          lt_environment TYPE senvi_tab.


* check zip is loaded
    SELECT SINGLE * FROM zaoc_sidb INTO ls_sidb.
    IF sy-subrc <> 0.
      inform( p_test    = myname
              p_kind    = c_note
              p_code    = '002' ).
      RETURN.
    ENDIF.

    lv_obj_type = object_type.

    CALL FUNCTION 'REPOSITORY_ENVIRONMENT_SET'
      EXPORTING
        obj_type       = lv_obj_type
        object_name    = object_name
      TABLES
        environment    = lt_environment
      EXCEPTIONS
        batch          = 1
        batchjob_error = 2
        not_executed   = 3
        OTHERS         = 4.
    IF sy-subrc <> 0 OR lines( lt_environment ) = 0.
      RETURN.
    ENDIF.

    SELECT * FROM zaoc_sidb
      INTO TABLE lt_result
      FOR ALL ENTRIES IN lt_environment
      WHERE object_type = lt_environment-type(4)
      AND object_name = lt_environment-object(40).        "#EC CI_SUBRC

    LOOP AT lt_result INTO ls_result.
      lv_note = ls_result-note.
      inform( p_test    = myname
              p_kind    = mv_errty
              p_code    = '001'
              p_param_1 = ls_result-object_type
              p_param_2 = ls_result-object_name
              p_param_3 = lv_note ).
    ENDLOOP.

  ENDMETHOD.
ENDCLASS.
