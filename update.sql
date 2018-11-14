-- update_template.sql
-- formatted with Poor Man's T-Sql Formatter

USE xyzCRM_MSCRM;
GO

SET NOCOUNT ON;-- [noformat]

RAISERROR(N'Updating ContactBase ...', 0, 1) WITH NOWAIT; --[/noformat]

BEGIN TRANSACTION;

BEGIN TRY
    UPDATE dbo.ContactBase
    SET new_CurrRegFlag = xa.new_CurrRegFlag
    OUTPUT 'UPDATE' AS ACTION
        ,inserted.ContactId
        ,inserted.new_StudentID
        ,deleted.new_CurrRegFlag AS prev_new_CurrRegFlag
        ,inserted.new_CurrRegFlag AS curr_new_CurrRegFlag
    FROM dbo.ContactBase c
    CROSS APPLY (
        SELECT IIF(EXISTS (
                    SELECT NULL
                    FROM dbo.new_registrationBase nr
                    WHERE nr.new_StudentId = c.ContactId
                        AND (
                            nr.new_Grade IS NULL
                            OR nr.new_Grade IN (
                                N'I'
                                ,N'pending'
                                )
                            )
                    ), 1, 0) AS new_CurrRegFlag
        ) xa
    WHERE NOT EXISTS (
            SELECT c.new_CurrRegFlag
            
            INTERSECT
            
            SELECT xa.new_CurrRegFlag
            );-- [noformat]

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
