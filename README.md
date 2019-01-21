# index_toolkit
Some tools for work with indexes in Oracle DB

## Demo
```sql
declare
  -- Input data
  v_schema all_tables.owner%type := 'myschema'; -- Schema name
  v_table all_tables.table_name%type :=  'temp_table'; -- Table object name
  v_columns varchar2(4000) := 'col1, col2, col5'; --Columns list separated by commas

  v_index_list varchar2(4000);
begin
	-- Get list of indexes separated by commas which relate to selected columns
	v_index_list := index_toolkit.get_index_list(v_schema, v_table, v_columns);
    dbms_output.put_line(v_index_list);
  
	index_toolkit.make_unused('gmo', v_index_list);
    index_toolkit.make_rebuild('gmo', v_index_list, TRUE); -- True-tell to use parallel index rebuild
exception
  when others then
    dbms_output.put_line('error: ' || dbms_utility.format_error_stack);
    dbms_output.put_line('stack: ' || dbms_utility.format_error_backtrace);
end;
```
