-- merge_template.sql
-- formatted with Poor Man's T-Sql Formatter

USE xyzCRM_MSCRM;
GO

SET NOCOUNT ON;

DECLARE @currDt DATETIME = GETUTCDATE();
DECLARE @userId UNIQUEIDENTIFIER = dbo.fn_FindUserGuid();
DECLARE @organizationId UNIQUEIDENTIFIER = (
        SELECT su.OrganizationId
        FROM dbo.SystemUserBase su
        WHERE su.SystemUserId = @userId
        );
DECLARE @ownerIdType INT = 8;

/* ****************************************************************************
   Create a table variable to hold Application optionset data
*/
DECLARE @applicationOptionSets TABLE (
    EnField NVARCHAR(100) NOT NULL
    ,OsLabel NVARCHAR(100) NOT NULL
    ,OsValue INT NOT NULL PRIMARY KEY CLUSTERED (
        EnField
        ,OsLabel
        )
    );

INSERT INTO @applicationOptionSets (
    EnField
    ,OsLabel
    ,OsValue
    )
SELECT sm.AttributeName AS EnField
    ,sm.[Value] AS OsLabel
    ,sm.AttributeValue AS OsValue
FROM dbo.StringMapBase sm
JOIN MetadataSchema.Entity en ON en.ObjectTypeCode = sm.ObjectTypeCode
WHERE en.[Name] = N'new_Application'
    AND sm.AttributeName IN (
        N'new_AcademicLevel'
        ,N'new_ApplicationStatus'
        ,N'statecode'
        );

DECLARE @academicLevelDoctorate INT = (
        SELECT os.OsValue
        FROM @applicationOptionSets os
        WHERE os.EnField = N'new_AcademicLevel'
            AND os.OsLabel = N'Doctorate'
        );
DECLARE @applicationStatusSubmitted INT = (
        SELECT os.OsValue
        FROM @applicationOptionSets os
        WHERE os.EnField = N'new_ApplicationStatus'
            AND os.OsLabel = N'Submitted'
        );
DECLARE @appStateCodeActive INT = (
        SELECT os.OsValue
        FROM @applicationOptionSets os
        WHERE os.EnField = N'statecode'
            AND os.OsLabel = N'Active'
        );

/* ****************************************************************************
   Insert/Update the records in CRM table
*/-- [noformat]
RAISERROR(N'Updating new_DoctoralApplicantBase ...', 0, 1) WITH NOWAIT; --[/noformat]

BEGIN TRANSACTION;

BEGIN TRY
    MERGE INTO dbo.new_DoctoralApplicantBase AS tgt
    USING (
        SELECT app.new_applicationId AS new_Application
            ,app.new_applicationname AS new_applicationid
            ,app.new_Program AS new_ProgramId
            ,COALESCE(app.new_RelatedStudent, app.new_Student) AS new_Student
            ,COALESCE(app.new_RelatedStudentID, con.new_StudentID) AS new_StudentID
        FROM dbo.new_ApplicationBase app
        LEFT JOIN dbo.ContactBase con ON con.ContactId = app.new_Student
        WHERE app.new_AcademicLevel = @academicLevelDoctorate
            AND app.new_ApplicationStatus = @applicationStatusSubmitted
            AND app.statecode = @appStateCodeActive
        ) AS src
        ON tgt.new_Application = src.new_Application
    WHEN NOT MATCHED BY TARGET
        THEN
            INSERT (
                new_doctoralapplicantId
                ,CreatedBy
                ,CreatedOn
                ,new_Application
                ,new_applicationid
                ,new_ProgramId
                ,new_Student
                ,new_StudentID
                ,OrganizationId
                ,statecode
                ,statuscode
                )
            VALUES (
                NEWID()
                ,@userId
                ,@currDt
                ,src.new_Application
                ,src.new_applicationid
                ,src.new_ProgramId
                ,src.new_Student
                ,src.new_StudentID
                ,@organizationId
                ,0
                ,1
                )
    WHEN MATCHED
        AND NOT EXISTS (
            SELECT tgt.new_applicationid
                ,tgt.new_ProgramId
                ,tgt.new_Student
                ,tgt.new_StudentID
            
            INTERSECT
            
            SELECT src.new_applicationid
                ,src.new_ProgramId
                ,src.new_Student
                ,src.new_StudentID
            )
        THEN
            UPDATE
            SET ModifiedBy = @userId
                ,ModifiedOn = @currDt
                ,tgt.new_applicationid = src.new_applicationid
                ,tgt.new_ProgramId = src.new_ProgramId
                ,tgt.new_Student = src.new_Student
                ,tgt.new_StudentID = src.new_StudentID
    OUTPUT $ACTION
        ,inserted.new_doctoralapplicantId
        ,inserted.new_Application
        ,deleted.new_applicationid AS prev_new_applicationid
        ,inserted.new_applicationid AS curr_new_applicationid
        ,deleted.new_ProgramId AS prev_new_ProgramId
        ,inserted.new_ProgramId AS curr_new_ProgramId
        ,deleted.new_Student AS prev_new_Student
        ,inserted.new_Student AS curr_new_Student
        ,deleted.new_StudentID AS prev_new_StudentID
        ,inserted.new_StudentID AS curr_new_StudentID;-- [noformat]

    RAISERROR(N'%d row(s) affected', 0, 1, @@ROWCOUNT) WITH NOWAIT; --[/noformat]
END TRY

BEGIN CATCH
    SELECT ERROR_NUMBER() AS ErrorNumber
        ,ERROR_SEVERITY() AS ErrorSeverity
        ,ERROR_STATE() AS ErrorState
        ,ERROR_PROCEDURE() AS ErrorProcedure
        ,ERROR_LINE() AS ErrorLine
        ,ERROR_MESSAGE() AS ErrorMessage;

    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;-- [noformat]
        RAISERROR(N'Transaction rolled back', 0, 1) WITH NOWAIT; --[/noformat]
    END
END CATCH;

IF @@TRANCOUNT > 0
BEGIN
    COMMIT TRANSACTION;-- [noformat]
    RAISERROR(N'Transaction committed', 0, 1) WITH NOWAIT; --[/noformat]
END
GO
