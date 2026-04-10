<cfcomponent output="false">

  <cffunction name="getCoupon" returntype="query">
    <cfargument name="search" default="">
    <cfargument name="status" default="">
    <cfargument name="page" default="1">
    <cfargument name="limit" default="5">

    <cfset var searchValue = trim(arguments.search)>
    <cfset var offset = (max(val(arguments.page),1) - 1) * arguments.limit>

    <cfquery name="coupons" datasource="#application.dsn#">
        SELECT *
        FROM coupons
        WHERE 1=1

        <cfif len(searchValue)>
            AND LOWER(code) LIKE 
            <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
        </cfif>

        <cfif arguments.status EQ "active">
            AND is_active = 1
        <cfelseif arguments.status EQ "blocked">
            AND is_active = 0
        </cfif>

        ORDER BY id DESC

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
    </cfquery>
    <cfreturn coupons>
  </cffunction>

  <cffunction name="getCouponCount" returntype="numeric">

    <cfargument name="search" default="">
    <cfargument name="status" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM coupons
        WHERE 1=1

        <cfif len(searchValue)>
            AND LOWER(code) LIKE 
            <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
        </cfif>

        <cfif arguments.status EQ "active">
            AND is_active = 1
        <cfelseif arguments.status EQ "blocked">
            AND is_active = 0
        </cfif>
    </cfquery>

    <cfreturn val(result.total)>
  </cffunction>

  <cffunction name="createCoupon" returntype="boolean">
        <cfargument name="code">
        <cfargument name="type">
        <cfargument name="value">
        <cfargument name="min">
        <cfargument name="max">
        <cfargument name="expiry">

        <cftry>
          <cfquery datasource="#application.dsn#">
            INSERT INTO coupons
            (code, discount_type, discount_value, min_amount, max_discount, expiry_date)
           
             VALUES (
                <cfqueryparam value="#arguments.code#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.type#" cfsqltype="cf_sql_varchar">,
                <cfqueryparam value="#arguments.value#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.min#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.max#" cfsqltype="cf_sql_decimal">,
                <cfqueryparam value="#arguments.expiry#" cfsqltype="cf_sql_date">
            ) 
          </cfquery>
          <cfreturn true>
        <cfcatch>
          <cfreturn false>
        </cfcatch>  
        </cftry>
  </cffunction>

  <cffunction name="updateCoupon">  
    <cfargument name="id">
    <cfargument name="code">
    <cfargument name="type">
    <cfargument name="value">
    <cfargument name="min">
    <cfargument name="max">
    <cfargument name="expiry">

     <cfquery datasource="#application.dsn#">
        UPDATE coupons
        SET code = <cfqueryparam value="#arguments.code#" cfsqltype="cf_sql_varchar">,
            discount_type = <cfqueryparam value="#arguments.type#" cfsqltype="cf_sql_varchar">,
            discount_value = <cfqueryparam value="#arguments.value#" cfsqltype="cf_sql_decimal">,
            min_amount = <cfqueryparam value="#arguments.min#" cfsqltype="cf_sql_decimal">,
            max_discount = <cfqueryparam value="#arguments.max#" cfsqltype="cf_sql_decimal">,
            expiry_date = <cfqueryparam value="#arguments.expiry#" cfsqltype="cf_sql_date">
        WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
    </cfquery>
  </cffunction>

  <cffunction name="toggleCoupon">
    <cfargument name="id">

    <cfquery datasource="#application.dsn#">
        UPDATE coupons
        SET is_active = NOT is_active
        WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
    </cfquery>
</cffunction>

</cfcomponent>