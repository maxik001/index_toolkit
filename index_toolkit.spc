create or replace package index_toolkit is

  -- Author  : Maksim O. Gusev
  -- Created : 15.01.2019 7:42:57
  -- Purpose : Some tools for work with indexes
  
  function get_index_list(
    v_schema all_tables.owner%type,
    v_table all_tables.table_name%type,
    v_columns varchar2
  ) return varchar2;

end index_toolkit;
