<cfcomponent output="false">
   <cffunction name="getAllCategories" access="public" returntype="query" output="false">
       <cfquery name="category" datasource="#application.dsn#">
          SELECT * FROM categories
       </cfquery>

       <cfreturn category>
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
</cfcomponent>