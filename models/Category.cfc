<cfcomponent output="false">
   <cffunction name="getAllCategories" access="public" returntype="query" output="false">
     <cfargument name="search" default="">
     <cfargument name="sort" default="">
     <cfargument name="page" default="1">
     <cfargument name="limit" default="2">

     <cfset var searchValue = trim(arguments.search)>
     <cfset var offset = (arguments.page - 1) * arguments.limit>


       <cfquery name="category" datasource="#application.dsn#">
          SELECT c.* FROM categories c
          WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(c.category_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(c.description) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>

        <cfif arguments.sort EQ "a_z">
            ORDER BY c.category_name ASC
        <cfelseif arguments.sort EQ "z_a">
            ORDER BY c.category_name DESC
        <cfelse>
            ORDER BY c.id DESC
        </cfif>

        LIMIT <cfqueryparam value="#arguments.limit#" cfsqltype="cf_sql_integer">
        OFFSET <cfqueryparam value="#offset#" cfsqltype="cf_sql_integer">
       </cfquery>

       <cfreturn category>
   </cffunction>

   <cffunction name="getCategoryCount" returntype="numeric">

    <cfargument name="search" default="">

    <cfset var searchValue = trim(arguments.search)>

    <cfquery name="result" datasource="#application.dsn#">
        SELECT COUNT(*) as total
        FROM categories c
        WHERE 1=1

        <cfif len(searchValue)>
            AND (
                LOWER(c.category_name) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">

                OR LOWER(c.description) LIKE 
                <cfqueryparam value="%#lcase(searchValue)#%" cfsqltype="cf_sql_varchar">
            )
        </cfif>
    </cfquery>

    <cfreturn result.total>

</cffunction>


   <cffunction name="getAllActiveCategory" access="public" returnType="query" output="false">
       <cfquery name="categories" datasource="#application.dsn#">
         SELECT id, category_name
         FROM categories
         WHERE is_active=1
       </cfquery>

       <cfreturn categories>
   </cffunction>

   <cffunction name="addCategory" access="public" returntype="boolean" output="false">
     <cfargument name="category_name" type="string" required="true">
     <cfargument name="description" type="string" required="true">
      <cftry>
        <cfquery datasource="#application.dsn#">
           INSERT INTO categories(category_name,description)
           VALUES (
            <cfqueryparam value="#arguments.category_name#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#arguments.description#" cfsqltype="cf_sql_varchar">
           )
        </cfquery>

        <cfreturn true>
       <cfcatch>
         <cfreturn false>
       </cfcatch>  
      </cftry>     
   </cffunction>

   <cffunction name="update_category" access="public" returntype="boolean" output="true">
          <cfargument name="id" type="numeric" required="true">
          <cfargument name="category_name" type="string" required="true">
          <cfargument name="description" type="string" required="true">
          <cftry>
            <cfquery datasource="#application.dsn#">
              UPDATE categories
              SET category_name = <cfqueryparam value="#arguments.category_name#" cfsqltype="cf_sql_varchar">,
                  description = <cfqueryparam value="#arguments.description#" cfsqltype="cf_sql_varchar">
              WHERE id=<cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">    
            </cfquery>

              <cfreturn true>

            <cfcatch>
              <cfreturn false>
            </cfcatch>
          </cftry>
   </cffunction>

   <cffunction name="toggleStatus" access="public" returntype="boolean" output="false">
        <cfargument name="id" type="numeric" required="true">
        <cfargument name="status" type="numeric" required="true">

        <cftry>
            <cfquery datasource="#application.dsn#">
                UPDATE categories
                SET is_active = <cfqueryparam value="#arguments.status#" cfsqltype="cf_sql_bit">
                WHERE id = <cfqueryparam value="#arguments.id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfreturn true>

            <cfcatch>
                <cfreturn false>
            </cfcatch>
        </cftry>
    </cffunction>

    <cffunction name="isCategoryExists" returntype="boolean" output="false">
    <cfargument name="category_name" required="true">

    <cfquery name="q" datasource="#application.dsn#">
        SELECT id 
        FROM categories 
        WHERE category_name = 
        <cfqueryparam value="#arguments.category_name#" cfsqltype="cf_sql_varchar">
    </cfquery>

    <cfreturn q.recordCount GT 0>
</cffunction>
</cfcomponent>