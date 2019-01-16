create or replace package body index_toolkit is

  -- Data types
  type dt_varchar_collection is table of varchar2(30);

  -- Constants 
  gc_parallel_ratio NUMERIC(7,2) := 0.25; -- What percentage of total CPU use to rebuild index when parallel mode 

  -- Exceptions
  E_UNKNOW_EXCEPTION EXCEPTION;

  -- Private functions and procedures
  
  /**
    * Return collection
    *
    * v_list List of values separated by commas
    * @return Collection of values
    */
  function list2collection(
    v_list varchar2
  ) return dt_varchar_collection is
    res dt_varchar_collection := dt_varchar_collection();
  begin
    -- Create collection of columns
    select UPPER(TRIM(REGEXP_SUBSTR(v_list, '[^,]+', 1, level))) val bulk collect
    into res
    from dual
    connect by REGEXP_SUBSTR(v_list, '[^,]+', 1, level) is not null;

    return res;    
  end;

  -- Public functions and procedures
  
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
    columns_list dt_varchar_collection := dt_varchar_collection();
    index_list1 dt_varchar_collection := dt_varchar_collection();
    index_list2 dt_varchar_collection := dt_varchar_collection();
    index_list_intersection dt_varchar_collection := dt_varchar_collection();
    v_regexp varchar2(4000);
    index_list_result varchar2(4000) := '';

  begin
    -- Create collection of columns
    columns_list := list2collection(v_columns);

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
    
    -- Return empty set if both of collection is empty
    if index_list1.count = 0 and index_list2.count = 0 then
      return index_list_result;
    end if;
    
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
  
  /**
   * Make indexes unused
   *
   * @param v_schema Schema name
   * @param v_index_list List of index names separated by commas
   */
  procedure make_unused(
    v_schema all_tables.owner%type,
    v_index_list varchar2
  ) is
    index_collection dt_varchar_collection := dt_varchar_collection();
    v_sql varchar2(4000);
  begin
    index_collection := list2collection(v_index_list);
  
    for i in 1 .. index_collection.count loop
      v_sql := 'alter index ' || v_schema || '.' || index_collection(i) || ' unusable';
      execute immediate v_sql;
    end loop;
    
  exception
    when OTHERS then
      raise E_UNKNOW_EXCEPTION;
  end;

  /**
   * Rebuild indexes
   *
   * @param v_schema Schema name
   * @param v_index_list List of index names separated by commas
   * @param v_flag_parallel Use parallel rebuild
   */
  procedure make_rebuild(
    v_schema all_tables.owner%type,
    v_index_list varchar2,
    v_flag_parallel BOOLEAN default FALSE
  ) is
    index_collection dt_varchar_collection := dt_varchar_collection();
    v_parallel_factor PLS_INTEGER := 1;
    v_cpu_count PLS_INTEGER;
    v_sql varchar2(4000);
  begin
    index_collection := list2collection(v_index_list);

    -- Calculate factor for parallel rebuild
    select ceil(t.value*gc_parallel_ratio)
    into v_cpu_count 
    from v$parameter t where t.name = 'parallel_max_servers';
    
    for i in 1 .. index_collection.count loop
      v_sql := 'alter index ' || v_schema || '.' || index_collection(i) || ' rebuild';
      
      if v_flag_parallel then
        v_sql := v_sql || ' parallel ' || v_cpu_count;
      end if;

      execute immediate v_sql;
      
      if v_flag_parallel then
        v_sql := 'alter index ' || v_schema || '.' || index_collection(i) || ' noparallel';
        execute immediate v_sql;
      end if;
      
    end loop;
    
  exception
    when OTHERS then
      raise E_UNKNOW_EXCEPTION;
  end;
  
end index_toolkit;
