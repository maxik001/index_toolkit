create or replace package body index_toolkit is

  -- Data types
  type dt_varchar_collection is table of varchar2(30);

  -- Exceptions
  E_UNKNOW_EXCEPTION EXCEPTION;

  /**
   * Return list of index names 
   *
   * @param v_schema Schema name
   * @param v_table Table name
   * @param v_columns List of column names separated by commas
   * @return List of index names separated by commas
   */
  function get_index_list(
    v_schema all_tables.owner%type,
    v_table all_tables.table_name%type,
    v_columns varchar2
  ) return varchar2 is

    -- Vars
    columns_list dt_varchar_collection;
    index_list1 dt_varchar_collection;
    index_list2 dt_varchar_collection;
    index_list_intersection dt_varchar_collection;
    v_regexp varchar2(4000);
    index_list_result varchar2(4000);

  begin
    columns_list := dt_varchar_collection();
    index_list1 := dt_varchar_collection();
    index_list2 := dt_varchar_collection();
    index_list_intersection := dt_varchar_collection();
      
    -- Create collection of columns
    select TRIM(REGEXP_SUBSTR(v_columns, '[^,]+', 1, level)) val bulk collect
    into columns_list
    from dual
    connect by REGEXP_SUBSTR(v_columns, '[^,]+', 1, level) is not null;

    -- Generate columns list with custom delimiter "|" (used in regexp_like, see below)
    for i in columns_list.first .. columns_list.last
    loop
      v_regexp := v_regexp || columns_list(i);
      if i <> columns_list.last then 
        v_regexp := v_regexp || '|';
      end if;
    end loop;

    -- Create first collection of index names based on all_ind_expressions
    for rec in (
      select t.index_name, t.column_expression from all_ind_expressions t
      where t.index_owner = UPPER(v_schema) and table_name = UPPER(v_table)
    ) loop
      if(regexp_like(rec.column_expression, v_regexp)) then
        index_list1.extend;
        index_list1(index_list1.count) := rec.index_name;
      end if;
    end loop;

    -- Create second collection of index names based on all_ind_columns
    v_regexp := '^(' || v_regexp || ')$'; -- looking for a complete match

    for rec in (
      select t.index_name, t.column_name from all_ind_columns t
      where t.index_owner = UPPER(v_schema) and table_name = UPPER(v_table)
    ) loop
      if(regexp_like(rec.column_name, v_regexp)) then
        index_list2.extend;
        index_list2(index_list2.count) := rec.index_name;
      end if;
    end loop;

    -- Preapre result collection
    index_list_intersection := index_list1 MULTISET UNION DISTINCT index_list2;

    -- Output
    for i in index_list_intersection.first .. index_list_intersection.last
    loop
      index_list_result := index_list_result || index_list_intersection(i);
      if(i <> index_list_intersection.last) then
        index_list_result := index_list_result || ',';
      end if;
    end loop;

    return index_list_result;

  exception
    when OTHERS then
      raise E_UNKNOW_EXCEPTION;
  end;
end index_toolkit;
