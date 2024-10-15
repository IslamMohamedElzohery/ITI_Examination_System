ALTER PROCEDURE [dbo].[AssignCourseToTrack]
    @Track_ID INT,
    @Crs_ID INT
AS
BEGIN
    -- Insert the course into the track
    INSERT INTO TRACKS_COURSES (Track_ID, Crs_ID)
    VALUES (@Track_ID, @Crs_ID);
END;
GO
---------------------------------------------------------------

ALTER PROCEDURE [dbo].[AssignInstructorToCourse]
    @Ins_Usr_ID INT,
    @Crs_ID INT
AS
BEGIN
    -- Insert the assignment into the INSTRUCTOR_COURSES table
    INSERT INTO INSTRUCTOR_COURSES (Ins_Usr_ID, Crs_ID)
    VALUES (@Ins_Usr_ID, @Crs_ID);
END;
GO
------------------------------------------------
ALTER PROCEDURE [dbo].[AssignStudentToCertificate]
    @S_Usr_ID INT,
    @Cer_ID INT,
    @Cer_Date DATE,
    @Cer_Code VARCHAR(10) = NULL -- optional parameter 
AS
BEGIN
    -- Check if the student is already assigned to the certificate
    IF EXISTS (SELECT 1 FROM STUDENT_CERTIFICATES WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID)
    BEGIN
        PRINT 'Student is already assigned to this certificate.';
    END
    ELSE
    BEGIN
        -- Insert the student-certificate assignment
        INSERT INTO STUDENT_CERTIFICATES (S_Usr_ID, Cer_ID, Cer_Date, Cer_Code)
        VALUES (@S_Usr_ID, @Cer_ID, @Cer_Date, @Cer_Code);
        PRINT 'Student assigned to the certificate successfully.';
    END
END;
GO
----------------------------------------
ALTER PROCEDURE [dbo].[AssignStudentToCourse]
    @S_Usr_ID INT,          -- Single student ID
    @Crs_ID INT,            -- Course ID to which the student will be assigned
    @Grade VARCHAR(3) = NULL  -- Optional grade
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insert the student into the STUDENT_COURSES table if not already assigned to the course
        INSERT INTO STUDENT_COURSES (S_Usr_ID, Crs_ID, Grade)
        SELECT @S_Usr_ID, @Crs_ID, @Grade
        WHERE NOT EXISTS (
            SELECT 1 
            FROM STUDENT_COURSES 
            WHERE S_Usr_ID = @S_Usr_ID AND Crs_ID = @Crs_ID
        );

        -- Commit the transaction if the insert succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;
GO
------------------------------------------------
ALTER PROCEDURE [dbo].[AssignStudentToCoursegen]
    @S_Usr_ID INT,            -- Single student ID
    @Crs_ID INT               -- Course ID to which the student will be assigned
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Insert the student into the STUDENT_COURSES table if not already assigned to the course
        -- and assign a random grade to the student
        INSERT INTO STUDENT_COURSES (S_Usr_ID, Crs_ID, Grade)
        SELECT @S_Usr_ID, 
               @Crs_ID, 
               CAST(
                   CASE 
                       WHEN RAND() < 0.75 THEN 75 + FLOOR(RAND() * (100 - 75 + 1))
                       ELSE 40 + FLOOR(RAND() * (74 - 40 + 1))
                   END AS VARCHAR(3)
               ) AS Grade
        WHERE NOT EXISTS (
            SELECT 1
            FROM STUDENT_COURSES SC
            WHERE SC.S_Usr_ID = @S_Usr_ID AND SC.Crs_ID = @Crs_ID
        );

        -- Commit the transaction if the insert succeeds
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;
GO
------------------------------
ALTER PROCEDURE [dbo].[AssignStudentToJob]
    @S_Usr_ID INT,
    @FJ_JobTitle VARCHAR(100),
    @FJ_Description VARCHAR(300),
    @FJ_Duration INT,
    @FJ_Date DATE,
    @FJ_Platform VARCHAR(50),
    @FJ_Cost MONEY,
    @FJ_PaymentMethod VARCHAR(50)
AS
BEGIN
    DECLARE @FJ_ID INT;

    -- Check if the student ID exists in the STUDENTS table
    IF NOT EXISTS (SELECT 1 FROM STUDENTS WHERE S_Usr_ID = @S_Usr_ID)
    BEGIN
        PRINT 'Student ID does not exist.';
        RETURN;
    END

    -- Check if the job title exists in the FREELANCING_JOBS table
    SELECT @FJ_ID = FJ_ID
    FROM FREELANCING_JOBS
    WHERE LTRIM(RTRIM(FJ_JobTitle)) = LTRIM(RTRIM(@FJ_JobTitle));

    -- If job title doesn't exist, insert it and retrieve the new FJ_ID
    IF @FJ_ID IS NULL
    BEGIN
        INSERT INTO FREELANCING_JOBS (FJ_JobTitle)
        VALUES (LTRIM(RTRIM(@FJ_JobTitle)));

        SET @FJ_ID = SCOPE_IDENTITY();  -- Get the newly inserted FJ_ID
    END

    -- Insert the student job into STUDENT_JOBS table
    INSERT INTO STUDENT_JOBS (S_Usr_ID, FJ_ID, FJ_Description, FJ_Duration, FJ_Date, FJ_Platform, FJ_Cost, FJ_PaymentMethod)
    VALUES (@S_Usr_ID, @FJ_ID, @FJ_Description, @FJ_Duration, @FJ_Date, @FJ_Platform, @FJ_Cost, @FJ_PaymentMethod);

    PRINT 'Student assigned to the job successfully.';
END;
GO
--------------------------------------------------------------
ALTER PROCEDURE [dbo].[AssignTrackToBranch]
    @Branch_ID INT,
    @Track_ID INT
AS
BEGIN
    INSERT INTO BRANCHES_TRACKS (Branch_ID, Track_ID)
    VALUES (@Branch_ID, @Track_ID);
END;
GO
-----------------------------
ALTER PROCEDURE [dbo].[AssignStudentToTrackAndBranch]
    @Std_IDs VARCHAR(MAX),  -- Comma-separated list of student IDs
    @Track_ID INT,
    @Branch_ID INT
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Split the list of student IDs and update their Track_ID and Branch_ID
        ;WITH StudentList AS (
            SELECT value AS S_Usr_ID
            FROM STRING_SPLIT(@Std_IDs, ',')
        )
        UPDATE STUDENTS
        SET Track_ID = @Track_ID,
            Branch_ID = @Branch_ID
        FROM STUDENTS S
        INNER JOIN StudentList SL
        ON S.S_Usr_ID = SL.S_Usr_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;
GO
---------------------------------------------------------------
ALTER PROCEDURE [dbo].[AuthenticateUser]
    @Email VARCHAR(100),
    @Password VARCHAR(256),  -- Pass the password as plain text
    @IsAuthenticated BIT OUTPUT  -- Output parameter indicating authentication result
AS
BEGIN
    -- Declare a variable to hold the hashed password from the database
    DECLARE @StoredPassword VARBINARY(256);
    DECLARE @HashedInputPassword VARBINARY(256);

    -- Set the output parameter to 0 (false) by default
    SET @IsAuthenticated = 0;
    
    -- Retrieve the stored hashed password for the given email
    SELECT @StoredPassword = Usr_Pass
    FROM USRS
    WHERE Usr_Email = @Email;
    
    -- Check if the email exists
    IF @StoredPassword IS NOT NULL
    BEGIN
        -- Hash the provided password using SHA2_256
        SET @HashedInputPassword = HASHBYTES('SHA2_256', @Password);
       
        -- Compare the hashed provided password with the stored hashed password
        IF @StoredPassword = @HashedInputPassword
        BEGIN
            -- Authentication is successful
            SET @IsAuthenticated = 1;
            PRINT 'Authentication successful.';
        END
        ELSE
        BEGIN
            -- Password does not match
            PRINT 'Authentication failed: Incorrect password.';
        END
    END
    ELSE
    BEGIN
        -- Email does not exist
        PRINT 'Authentication failed: Email does not exist.';
    END
END;
GO
----------------------------------------------------------------------
ALTER PROCEDURE [dbo].[DeleteBranch]
    @Branch_ID INT
AS
BEGIN
    DELETE FROM BRANCHES
    WHERE Branch_ID = @Branch_ID;
END;
GO
-----------------
ALTER PROCEDURE [dbo].[DeleteCertificate]
    @Cer_ID INT
AS
BEGIN
    -- Check if the certificate exists
    IF EXISTS (SELECT 1 FROM CERTIFICATES WHERE Cer_ID = @Cer_ID)
    BEGIN
        -- If it exists, delete the certificate
        DELETE FROM CERTIFICATES WHERE Cer_ID = @Cer_ID;
        PRINT 'Certificate deleted successfully.';
    END
    ELSE
    BEGIN
        -- If it doesn't exist, print a message
        PRINT 'Certificate ID does not exist.';
    END
END;
GO
---------------
ALTER PROCEDURE [dbo].[DeleteCourse]
    @Crs_ID INT
AS
BEGIN
    DELETE FROM COURSES
    WHERE Crs_ID = @Crs_ID;
END;
GO
-------------------------------------
ALTER PROCEDURE [dbo].[DeleteFreelancingJob]
    @FJ_ID INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM FREELANCING_JOBS WHERE FJ_ID = @FJ_ID)
    BEGIN
        DELETE FROM FREELANCING_JOBS WHERE FJ_ID = @FJ_ID;
        PRINT 'Job deleted successfully.';
    END
    ELSE
    BEGIN
        PRINT 'Job ID does not exist.';
    END
END;
GO
------------------------------------------------
ALTER PROCEDURE [dbo].[DeleteInstructorQualification]
    @Ins_Usr_ID INT,
    @Ins_Qualification VARCHAR(100)
AS
BEGIN
    DELETE FROM INSTRUCTOR_QUALIFICATIONS
    WHERE Ins_Usr_ID = @Ins_Usr_ID
    AND Ins_Qualification = @Ins_Qualification;
END;
GO
------------------------------------------------
ALTER PROCEDURE [dbo].[DeleteQuestion]
    @Q_ID INT
AS
BEGIN
    -- Delete the question
    DELETE FROM QUESTIONS
    WHERE Q_ID = @Q_ID;
END;
GO
---------------
ALTER PROCEDURE [dbo].[DeleteTopic]
    @Topic_ID INT
AS
BEGIN
    DELETE FROM TOPICS
    WHERE Topic_ID = @Topic_ID;
END;
GO
-------------------------------
ALTER PROCEDURE [dbo].[DeleteTrack]
    @Track_ID INT
AS
BEGIN
    DELETE FROM TRACKS
    WHERE Track_ID = @Track_ID;
END;
GO
------------------------------
ALTER PROCEDURE [dbo].[DeleteUser]
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of IDs or NULL for all users
AS
BEGIN
    -- If an ID list is provided, split the comma-separated list into a table
    IF @Usr_IDs IS NOT NULL
    BEGIN
        -- Create a temporary table to store the IDs
        DECLARE @IDTable TABLE (Usr_ID INT);

        -- Insert the IDs into the temporary table
        INSERT INTO @IDTable (Usr_ID)
        SELECT value FROM STRING_SPLIT(@Usr_IDs, ',');

        -- Delete from USRS based on the provided IDs
        DELETE FROM USRS
        WHERE Usr_ID IN (SELECT Usr_ID FROM @IDTable);
    END
    ELSE
    BEGIN
        -- No ID list provided, delete all users
        DELETE FROM USRS;
    END
    
    PRINT 'Users deleted successfully.';
END;
GO
---------------------------------
ALTER PROCEDURE [dbo].[DisplayBranchInfo]
    @Branch_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of Branch IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @BranchTable TABLE (Branch_ID INT);

    -- Populate the temporary table with IDs if provided
    IF @Branch_IDs IS NOT NULL
    BEGIN
        INSERT INTO @BranchTable (Branch_ID)
        SELECT CAST(value AS INT) 
        FROM STRING_SPLIT(@Branch_IDs, ',');
    END

    -- Retrieve branch information with track and instructor details
    SELECT  
        B.Branch_ID,
        B.Branch_Loc,
        T.Track_ID,
        T.Track_Name,
        I.Ins_Usr_ID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName
 FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN TRACKS T ON I.Ins_Usr_ID = T.SV_Usr_ID
    INNER JOIN BRANCHES_TRACKS BT ON T.Track_ID = BT.Track_ID
    INNER JOIN BRANCHES B ON B.Branch_ID = BT.Branch_ID
    WHERE (@Branch_IDs IS NULL OR B.Branch_ID IN (SELECT Branch_ID FROM @BranchTable));
END
GO
------------------------------------------------------------------
ALTER PROCEDURE [dbo].[DisplayCourseTrackInfo]
    @Crs_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of Course IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @CourseTable TABLE (Crs_ID INT);

    -- Populate the temporary table with IDs if provided
    IF @Crs_IDs IS NOT NULL
    BEGIN
        INSERT INTO @CourseTable (Crs_ID)
        SELECT CAST(value AS INT) 
        FROM STRING_SPLIT(@Crs_IDs, ',');
    END

    -- Retrieve course information with track and instructor details
    SELECT  
        C.Crs_ID, 
        C.Crs_Name, 
        C.Crs_Duration,
        TPC.Topic_ID, 
        TPC.Topic_Name,
        T.Track_ID, 
        T.Track_Name, 
        I.Ins_Usr_ID, 
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName
    FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN TRACKS T ON I.Ins_Usr_ID = T.SV_Usr_ID
    INNER JOIN TRACKS_COURSES TC ON T.Track_ID = TC.Track_ID
    INNER JOIN COURSES C ON C.Crs_ID = TC.Crs_ID
    INNER JOIN TOPICS TPC ON TPC.Topic_ID = C.Topic_ID
    WHERE (@Crs_IDs IS NULL OR C.Crs_ID IN (SELECT Crs_ID FROM @CourseTable));
END;
GO
---------------------
ALTER PROCEDURE [dbo].[DisplayTrackCourseInfo]
    @Track_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of Track IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @TrackTable TABLE (Track_ID INT);

    -- Populate the temporary table with IDs if provided
    IF @Track_IDs IS NOT NULL
    BEGIN
        INSERT INTO @TrackTable (Track_ID)
        SELECT CAST(value AS INT) 
        FROM STRING_SPLIT(@Track_IDs, ',');
    END

    -- Retrieve track information with course and topic details
    SELECT  
        T.Track_ID, 
        T.Track_Name, 
        I.Ins_Usr_ID, 
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName,
        C.Crs_ID, 
        C.Crs_Name, 
        C.Crs_Duration,
        TPC.Topic_ID, 
        TPC.Topic_Name
    FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN TRACKS T ON I.Ins_Usr_ID = T.SV_Usr_ID
    INNER JOIN TRACKS_COURSES TC ON T.Track_ID = TC.Track_ID
    INNER JOIN COURSES C ON C.Crs_ID = TC.Crs_ID
    INNER JOIN TOPICS TPC ON TPC.Topic_ID = C.Topic_ID
    WHERE (@Track_IDs IS NULL OR T.Track_ID IN (SELECT Track_ID FROM @TrackTable));
END;
GO
-------------------------------------
ALTER PROCEDURE [dbo].[DisplayTrackInfo]
    @Track_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of Track IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @TrackTable TABLE (Track_ID INT);

    -- Populate the temporary table with IDs if provided
    IF @Track_IDs IS NOT NULL
    BEGIN
        INSERT INTO @TrackTable (Track_ID)
        SELECT CAST(value AS INT) 
        FROM STRING_SPLIT(@Track_IDs, ',');
    END

    -- Retrieve track information with instructor and branch details
    SELECT  T.Track_ID, T.Track_Name,
			I.Ins_Usr_ID, 
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName,
            B.Branch_ID, B.Branch_Loc
    FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN TRACKS T ON I.Ins_Usr_ID = T.SV_Usr_ID
    INNER JOIN BRANCHES_TRACKS BT ON T.Track_ID = BT.Track_ID
    INNER JOIN BRANCHES B ON B.Branch_ID = BT.Branch_ID
    WHERE (@Track_IDs IS NULL OR T.Track_ID IN (SELECT Track_ID FROM @TrackTable));
END;
GO
---------------------------------------------------------------------------
ALTER PROCEDURE [dbo].[ExamCorrection] 
	@Exam_ID INT 
AS
BEGIN 
	BEGIN TRANSACTION;
    BEGIN TRY
		-- Check if the Exam exists
        IF NOT EXISTS (SELECT 1 FROM EXAMS WHERE Exam_ID = @Exam_ID)
        BEGIN 
            PRINT 'Exam Not Exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END

		-- Display the Correct Answers Of Questions in the Exam 
		SELECT Q.Q_ID, Q.Q_Text, Q.Q_CorrectAnswer 
		FROM EXAMS E
		INNER JOIN EXAM_GEN EG 
			ON E.Exam_ID = EG.Exam_ID
		INNER JOIN QUESTIONS Q
			ON Q.Q_ID = EG.Q_ID
		WHERE E.Exam_ID = @Exam_ID;

		-- If everything goes well, commit the transaction
		COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END
GO
--------------------------------
ALTER PROCEDURE [dbo].[ExamGeneration]
    @Crs_Name VARCHAR(100),  -- Course ID to be inserted into EXAMS and associated with the questions
	@NumberOfMCQ INT, -- Number of MCQ in the Exam
	@NumberOfTF INT  -- Number of True\False Questions in the Exam
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
		-- Trim Tailing/leading Spaces 
		SET @Crs_Name = dbo.CollapsedSpaces(@Crs_Name);
        -- Check if the course exists
        IF NOT EXISTS (	SELECT 1 FROM [dbo].[COURSES]
						WHERE dbo.RemoveAllSpaces(Crs_Name) = dbo.RemoveAllSpaces(@Crs_Name)
		)
        BEGIN 
            PRINT 'Course Not Exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END
		-- Get The Course ID Based on Course Name
		DECLARE @Crs_ID INT ;
		SELECT @Crs_ID = Crs_ID
		FROM COURSES
		WHERE dbo.RemoveAllSpaces(Crs_Name) = dbo.RemoveAllSpaces(@Crs_Name) 

        -- Declare a variable to hold the new Exam_ID
        DECLARE @NewExam_ID INT;

        -- Insert the exam record into EXAMS and get the new Exam_ID
        INSERT INTO EXAMS (Crs_ID)
        VALUES (@Crs_ID);

        -- Retrieve the last inserted Exam_ID
        SET @NewExam_ID = SCOPE_IDENTITY();

        -- Insert random MCQ questions into EXAM_GEN
        ;WITH RandomMCQs AS (
            SELECT TOP (@NumberOfMCQ) Q_ID
            FROM QUESTIONS
            WHERE Q_Type = 1 AND Crs_ID = @Crs_ID -- MCQ type
            ORDER BY NEWID()  -- Random order
        )
        INSERT INTO EXAM_GEN (Exam_ID, Q_ID)
        SELECT @NewExam_ID, Q_ID
        FROM RandomMCQs;

        -- Insert random T/F questions into EXAM_GEN
        ;WITH RandomTFs AS (
            SELECT TOP (@NumberOfTF) Q_ID
            FROM QUESTIONS
            WHERE Q_Type = 2 AND Crs_ID = @Crs_ID -- T/F type
            ORDER BY NEWID()  -- Random order
        )
        INSERT INTO EXAM_GEN (Exam_ID, Q_ID)
        SELECT @NewExam_ID, Q_ID
        FROM RandomTFs;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;

        -- Call the ExamPresentation procedure to present the exam details
        EXEC ExamPresentation @NewExam_ID;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;
GO
-------------------------------------------------------------
ALTER PROCEDURE [dbo].[ExamPresentation] @Exam_ID INT
AS
BEGIN
    -- Select exam details along with course, question, and available answers
    SELECT E.Exam_ID, 
           C.Crs_ID, 
           C.Crs_Name,
           Q.Q_ID, 
           Q.Q_Text, 
           Q.Q_Type,
           A.Q_AvailableAnswers
    FROM EXAMS E
    INNER JOIN COURSES C
        ON C.Crs_ID = E.Crs_ID
    INNER JOIN EXAM_GEN EG
        ON E.Exam_ID = EG.Exam_ID
    INNER JOIN QUESTIONS Q
        ON Q.Q_ID = EG.Q_ID
    INNER JOIN QUESTIONS_AvailableAnswers A
        ON Q.Q_ID = A.Q_ID
	WHERE E.Exam_ID = @Exam_ID
    ORDER BY Q.Q_Type DESC, E.Exam_ID, Q.Q_ID;
END;
GO
-------------------------------------------------
ALTER PROCEDURE [dbo].[ExamQuestion_StudentAnswer]
	@S_Usr_ID INT , @Exam_ID INT
AS
BEGIN 
	BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            PRINT 'Student does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END 

        -- Check if the exam exists
        IF NOT EXISTS (SELECT 1 FROM [EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Exam does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

       -- Get Student Answers of Exam Questions
	   SELECT Q.Q_Text , Q.Q_CorrectAnswer , SA.Std_Answer , SA.Status 
	   FROM  STUDENT_ANSWERS SA
	   INNER JOIN QUESTIONS Q
			ON Q.Q_ID = SA.Q_ID
		WHERE S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID 


        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        PRINT 'An error occurred while retrieving the student exam results.';
        THROW;
    END CATCH;
END
GO
--------------------------------------------
ALTER PROCEDURE [dbo].[ExamQuestions_Choices]
	@Exam_ID INT
AS 
BEGIN 
	BEGIN TRANSACTION;
    BEGIN TRY
        -- Check if the Exam ID exists
        IF NOT EXISTS (SELECT 1 FROM [EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN 
            PRINT 'EXAM Not Exists';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        
        -- Select exam details along with course, question, and available answers
        SELECT E.Exam_ID, 
               C.Crs_Name,
               Q.Q_Text, 
               A.Q_AvailableAnswers
        FROM [EXAMS] E
        INNER JOIN [COURSES] C
            ON C.Crs_ID = E.Crs_ID
        INNER JOIN [EXAM_GEN] EG
            ON E.Exam_ID = EG.Exam_ID
        INNER JOIN [QUESTIONS] Q
            ON Q.Q_ID = EG.Q_ID
        INNER JOIN [QUESTIONS_AvailableAnswers] A
            ON Q.Q_ID = A.Q_ID
        WHERE E.Exam_ID = @Exam_ID
        ORDER BY Q.Q_Type DESC;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH

END
GO
-----------------------------------------------------
ALTER PROCEDURE [dbo].[GetCertificateInfo]
    @Cer_IDs VARCHAR(MAX) = NULL
AS
BEGIN
    IF @Cer_IDs IS NULL
    BEGIN
        -- Select all certificates
        SELECT * FROM CERTIFICATES;
    END
    ELSE
    BEGIN
        -- Select one or multiple certificates based on IDs
        SELECT * FROM CERTIFICATES
        WHERE Cer_ID IN (SELECT value FROM STRING_SPLIT(@Cer_IDs, ','));
    END
END;
GO
--------------------------------
ALTER PROCEDURE [dbo].[GetCertificateStudentsInfo]
    @Cer_IDs VARCHAR(MAX) = NULL  -- Comma-separated IDs or NULL for all
AS
BEGIN
    IF @Cer_IDs IS NULL
    BEGIN
        -- Select all certificates and their assigned students
        SELECT  C.Cer_ID, C.Cer_Name, 
                S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName, 
                SC.Cer_Date, SC.Cer_Code  
        FROM CERTIFICATES C
        INNER JOIN STUDENT_CERTIFICATES SC
            ON C.Cer_ID = SC.Cer_ID
        INNER JOIN STUDENTS S
            ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN USRS U 
            ON U.Usr_ID = S.S_Usr_ID
		ORDER BY C.Cer_ID;
    END
    ELSE
    BEGIN
        -- Select specific certificates and their assigned students based on provided IDs
        SELECT  C.Cer_ID, C.Cer_Name, 
                S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName, 
                SC.Cer_Date, SC.Cer_Code  
        FROM CERTIFICATES C
        INNER JOIN STUDENT_CERTIFICATES SC
            ON C.Cer_ID = SC.Cer_ID
        INNER JOIN STUDENTS S
            ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN USRS U 
            ON U.Usr_ID = S.S_Usr_ID
        WHERE C.Cer_ID IN (SELECT value FROM STRING_SPLIT(@Cer_IDs, ','))
		ORDER BY C.Cer_ID;
		
    END
END;
Go
-------------------------------------------------
ALTER PROCEDURE [dbo].[GetCourseInstructorDetails]
    @Crs_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of course IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @CourseTable TABLE (Crs_ID INT);

    -- Populate the temporary table
    IF @Crs_IDs IS NOT NULL
    BEGIN
        INSERT INTO @CourseTable (Crs_ID)
        SELECT CAST(value AS INT) FROM STRING_SPLIT(@Crs_IDs, ',');
    END

    -- Retrieve instructor and course details
    SELECT  
		IC.Crs_ID AS CourseID,
        C.Crs_Name AS CourseName,
        I.Ins_Usr_ID AS InstructorID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName
    FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN INSTRUCTOR_COURSES IC ON I.Ins_Usr_ID = IC.Ins_Usr_ID
    INNER JOIN COURSES C ON C.Crs_ID = IC.Crs_ID
    WHERE (@Crs_IDs IS NULL OR IC.Crs_ID IN (SELECT Crs_ID FROM @CourseTable));
END;
----------------------------------
GO
ALTER PROCEDURE [dbo].[GetCourseStudentsInfo]
    @Crs_IDs VARCHAR(MAX)  -- Comma-separated list of course IDs
AS
BEGIN
    SELECT
        C.Crs_ID, C.Crs_Name , 
		S.S_Usr_ID, 
		CONCAT_WS(' ', U.Usr_Fname , U.Usr_Mname , U.Usr_Lname) AS StudentName

    FROM USRS U
	INNER JOIN STUDENTS S 
		ON U.Usr_ID = S.S_Usr_ID
    INNER JOIN STUDENT_COURSES SC
        ON S.S_Usr_ID = SC.S_Usr_ID
    INNER JOIN COURSES C
        ON SC.Crs_ID = C.Crs_ID
    WHERE C.Crs_ID IN (SELECT value FROM STRING_SPLIT(@Crs_IDs, ','))
	ORDER BY C.Crs_ID;
END;
------------------------------------------
GO

ALTER PROCEDURE [dbo].[GetInstructorCourseDetails]
    @Ins_Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of instructor IDs
AS
BEGIN
    -- Prepare a temporary table for IDs if needed
    DECLARE @InstructorTable TABLE (Ins_Usr_ID INT);

    -- Populate the temporary table
    IF @Ins_Usr_IDs IS NOT NULL
    BEGIN
        INSERT INTO @InstructorTable (Ins_Usr_ID)
        SELECT CAST(value AS INT) FROM STRING_SPLIT(@Ins_Usr_IDs, ',');
    END

    -- Retrieve instructor and course details
    SELECT  
        I.Ins_Usr_ID AS InstructorID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS InstructorName,
        IC.Crs_ID AS CourseID,
        C.Crs_Name AS CourseName
    FROM USRS U
    INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
    INNER JOIN INSTRUCTOR_COURSES IC ON I.Ins_Usr_ID = IC.Ins_Usr_ID
    INNER JOIN COURSES C ON C.Crs_ID = IC.Crs_ID
    WHERE (@Ins_Usr_IDs IS NULL OR I.Ins_Usr_ID IN (SELECT Ins_Usr_ID FROM @InstructorTable));
END;
----------------------------
GO
ALTER PROCEDURE [dbo].[GetJobStudentsInfo]
    @FJ_JobTitle NVARCHAR(MAX) = NULL  -- Optional: Accept a comma-separated list of job titles or NULL for all
AS
BEGIN
    -- Declare a table variable to store the list of job IDs
    DECLARE @JobIDs TABLE (FJ_ID INT);

    -- If no specific job titles are passed, insert all job IDs from the FREELANCING_JOBS table
    IF @FJ_JobTitle IS NULL
    BEGIN
        INSERT INTO @JobIDs (FJ_ID)
        SELECT FJ_ID FROM FREELANCING_JOBS;
    END
    ELSE
    BEGIN
        -- If specific job titles are passed, retrieve their IDs and insert into the table variable
        INSERT INTO @JobIDs (FJ_ID)
        SELECT FJ_ID
        FROM FREELANCING_JOBS
        WHERE FJ_JobTitle IN (SELECT LTRIM(RTRIM(value)) FROM STRING_SPLIT(@FJ_JobTitle, ','));
    END

    -- Select the students' jobs information for the specified or all job titles
    SELECT  
        F.FJ_JobTitle,
        S.S_Usr_ID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
        SJ.FJ_Description,
        SJ.FJ_Date,
        SJ.FJ_Duration,
        SJ.FJ_Platform,
        SJ.FJ_Cost,
        SJ.FJ_PaymentMethod
    FROM USRS U
    INNER JOIN STUDENTS S
        ON U.Usr_ID = S.S_Usr_ID
    INNER JOIN STUDENT_JOBS SJ
        ON S.S_Usr_ID = SJ.S_Usr_ID
    INNER JOIN FREELANCING_JOBS F
        ON F.FJ_ID = SJ.FJ_ID
    WHERE F.FJ_ID IN (SELECT FJ_ID FROM @JobIDs)
    ORDER BY F.FJ_ID;
END;
------------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[GetStudentCertificatesInfo]
    @S_Usr_IDs VARCHAR(MAX) = NULL  -- Comma-separated IDs or NULL for all
AS
BEGIN
    IF @S_Usr_IDs IS NULL
    BEGIN
        -- Select all students and their assigned certificates
        SELECT  S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
                C.Cer_ID, C.Cer_Name, 
                SC.Cer_Date, SC.Cer_Code  
        FROM CERTIFICATES C
        INNER JOIN STUDENT_CERTIFICATES SC
            ON C.Cer_ID = SC.Cer_ID
        INNER JOIN STUDENTS S
            ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN USRS U 
            ON U.Usr_ID = S.S_Usr_ID
        ORDER BY S.S_Usr_ID;
    END
    ELSE
    BEGIN
        -- Select specific students and their assigned certificates based on provided IDs
        SELECT  S.S_Usr_ID, CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
                C.Cer_ID, C.Cer_Name, 
                SC.Cer_Date, SC.Cer_Code  
        FROM CERTIFICATES C
        INNER JOIN STUDENT_CERTIFICATES SC
            ON C.Cer_ID = SC.Cer_ID
        INNER JOIN STUDENTS S
            ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN USRS U 
            ON U.Usr_ID = S.S_Usr_ID
        WHERE S.S_Usr_ID IN (SELECT value FROM STRING_SPLIT(@S_Usr_IDs, ','))
        ORDER BY S.S_Usr_ID;
    END
END;
-----------------------------------
GO
ALTER PROCEDURE [dbo].[GetStudentCoursesInfo]
    @Std_IDs VARCHAR(MAX)  -- Comma-separated list of student IDs
AS
BEGIN
    SELECT
        S.S_Usr_ID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
        C.Crs_ID,
        C.Crs_Name,
        SC.Grade  -- Include the Grade column
    FROM USRS U
    INNER JOIN STUDENTS S 
        ON U.Usr_ID = S.S_Usr_ID
    INNER JOIN STUDENT_COURSES SC
        ON S.S_Usr_ID = SC.S_Usr_ID
    INNER JOIN COURSES C
        ON SC.Crs_ID = C.Crs_ID
    WHERE S.S_Usr_ID IN (SELECT value FROM STRING_SPLIT(@Std_IDs, ','))
    ORDER BY S.S_Usr_ID;
END;
-----------------------------------
GO
ALTER PROCEDURE [dbo].[GetStudentExamResults]
    @S_Usr_ID INT,          -- Student ID
    @Exam_ID INT            -- Exam ID
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN
            PRINT 'Student does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END 

        -- Check if the exam exists
        IF NOT EXISTS (SELECT 1 FROM [EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Exam does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Declare variables
        DECLARE @CorrectAnswers INT;
        DECLARE @WrongAnswers INT;
        DECLARE @TotalQuestions INT;
        DECLARE @Score INT;
        DECLARE @Crs_ID INT;

        -- Calculate the number of correct answers
        SET @CorrectAnswers = 
        (
            SELECT COUNT(*)
            FROM [STUDENT_ANSWERS]
            WHERE Status = 1 AND S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID
        );

        -- Calculate the number of wrong answers
        SET @WrongAnswers = 
        (
            SELECT COUNT(*)
            FROM [STUDENT_ANSWERS]
            WHERE Status = 0 AND S_Usr_ID = @S_Usr_ID AND Exam_ID = @Exam_ID
        );

        -- Calculate the total number of questions
        SET @TotalQuestions = 
        (
            SELECT COUNT(DISTINCT Q_ID)
            FROM [EXAM_GEN]
            WHERE Exam_ID = @Exam_ID
        );

        -- Calculate the score, avoid division by zero
        IF @TotalQuestions > 0
            SET @Score = (@CorrectAnswers * 100) / @TotalQuestions;
        ELSE
            SET @Score = 0;

        -- Return the results
       

        -- Get the Crs_ID of the Exam
        SELECT @Crs_ID = Crs_ID 
        FROM [COURSES]  -- Assuming the correct table for courses
        WHERE Crs_ID = 
        (
            SELECT Crs_ID 
            FROM [EXAMS]
            WHERE Exam_ID = @Exam_ID
        );

        -- Update the student's score in the STUDENT_COURSES table
		if @TotalQuestions >0 
		begin
			UPDATE [STUDENT_COURSES]
			SET Grade = CAST(@Score AS VARCHAR(5)) + ' %'
			WHERE S_Usr_ID = @S_Usr_ID AND Crs_ID = @Crs_ID;
		end
PRINT 'Crs_ID: ' + CAST(@Crs_ID AS VARCHAR);
PRINT 'S_Usr_ID: ' + CAST(@S_Usr_ID AS VARCHAR);
PRINT 'Exam_ID: ' + CAST(@Exam_ID AS VARCHAR);
PRINT 'Crs_ID: ' + ISNULL(CAST(@Crs_ID AS VARCHAR), 'NULL');
PRINT 'CorrectAnswers: ' + CAST(@CorrectAnswers AS VARCHAR);
PRINT 'WrongAnswers: ' + CAST(@WrongAnswers AS VARCHAR);
PRINT 'TotalQuestions: ' + CAST(@TotalQuestions AS VARCHAR);
PRINT 'Score: ' + CAST(@Score AS VARCHAR);
SELECT * 
FROM [STUDENT_COURSES] 
WHERE S_Usr_ID = @S_Usr_ID;
SELECT * 
FROM [STUDENT_COURSES] 
WHERE Crs_ID = @Crs_ID;
SELECT * 
FROM [STUDENT_COURSES] 
WHERE S_Usr_ID = @S_Usr_ID AND Crs_ID = @Crs_ID;




        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        PRINT 'An error occurred while retrieving the student exam results.';
        THROW;
    END CATCH;
END;
--------------------------------------------
GO
ALTER PROCEDURE [dbo].[GetStudentJobsInfo]
    @S_Usr_IDs NVARCHAR(MAX) = NULL  -- Optional: Accept a comma-separated list of Student IDs or NULL for all
AS
BEGIN
    -- Declare a table variable to store the list of student IDs
    DECLARE @StudentIDs TABLE (S_Usr_ID INT);

    -- If no specific IDs are passed, insert all student IDs from the STUDENTS table
    IF @S_Usr_IDs IS NULL
    BEGIN
        INSERT INTO @StudentIDs (S_Usr_ID)
        SELECT S_Usr_ID FROM STUDENTS;
    END
    ELSE
    BEGIN
        -- If specific IDs are passed, split them and insert into the table variable
        INSERT INTO @StudentIDs (S_Usr_ID)
        SELECT value
        FROM STRING_SPLIT(@S_Usr_IDs, ',');
    END

    -- Select the jobs information for the specified or all student IDs
    SELECT  
        S.S_Usr_ID,
        CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
        F.FJ_JobTitle,
        SJ.FJ_Description,
        SJ.FJ_Date,
        SJ.FJ_Duration,
        SJ.FJ_Platform,
        SJ.FJ_Cost,
        SJ.FJ_PaymentMethod
    FROM USRS U
    INNER JOIN STUDENTS S
        ON U.Usr_ID = S.S_Usr_ID
    INNER JOIN STUDENT_JOBS SJ
        ON S.S_Usr_ID = SJ.S_Usr_ID
    INNER JOIN FREELANCING_JOBS F
        ON F.FJ_ID = SJ.FJ_ID
    WHERE S.S_Usr_ID IN (SELECT S_Usr_ID FROM @StudentIDs)
    ORDER BY S.S_Usr_ID;
END;
--------------------------------
GO
ALTER PROCEDURE [dbo].[GetStudentsByBranchLocations]
    @Branch_Locs NVARCHAR(MAX)  -- Comma-separated list of branch locations
AS
BEGIN
    -- Start the transaction
    BEGIN TRANSACTION;
    BEGIN TRY
		SET @Branch_Locs = dbo.RemoveAllSpaces(@Branch_Locs);
        -- Variable to hold split branch locations
        DECLARE @BranchTable TABLE (Branch_Loc NVARCHAR(100));

        -- Split the comma-separated values into rows (SQL Server 2016+)
        INSERT INTO @BranchTable (Branch_Loc)
        SELECT value
        FROM STRING_SPLIT(@Branch_Locs, ',');

        -- Check if any branches do not exist
        IF EXISTS (
            SELECT Branch_Loc 
            FROM @BranchTable
            WHERE Branch_Loc NOT IN (SELECT Branch_Loc FROM BRANCHES)  -- Assuming 'Branches' is the branch table
        )
        BEGIN
            PRINT 'One or more branch locations do not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END
        -- Display students in the valid branches
        SELECT	B.Branch_Loc , 
				CONCAT_WS( ' ' ,U.Usr_Fname , U.Usr_Mname , U.Usr_Lname) AS StudentName , U.Usr_ID, 
				 U.Usr_Gender , U.Usr_Age , U.Usr_City , U.Usr_GOV 
		FROM USRS U
		INNER JOIN STUDENTS S
			ON U.Usr_ID = S.S_Usr_ID
		INNER JOIN BRANCHES B
			ON B.Branch_ID = S.Branch_ID
		WHERE dbo.RemoveAllSpaces(B.Branch_Loc) IN(SELECT Branch_Loc FROM @BranchTable)
		ORDER BY B.Branch_Loc

        -- Commit the transaction
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors and rollback the transaction
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rollback the transaction
        ROLLBACK TRANSACTION;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
Go
------------------------------------------
ALTER PROCEDURE [dbo].[GetUserInfo]
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Comma-separated list of IDs or NULL for all users
AS
BEGIN
    -- Create a temporary table to store the IDs if provided
    IF @Usr_IDs IS NOT NULL
    BEGIN
        -- Split the comma-separated list into a table
        DECLARE @IDTable TABLE (Usr_ID INT);

        -- Insert the IDs into the temporary table
        INSERT INTO @IDTable (Usr_ID)
        SELECT value FROM STRING_SPLIT(@Usr_IDs, ',');
    END

    -- Retrieve basic user information based on provided IDs or all users
    SELECT
        U.Usr_ID,
        U.Usr_Fname,
        U.Usr_Mname,
        U.Usr_Lname,
        U.Usr_Email,
        U.Usr_Phone,
        U.Usr_DOB,
        U.Usr_City,
        U.Usr_GOV,
        U.Usr_Facebook,
        U.Usr_LinkedIn,
        U.Usr_Role,
        U.Usr_Gender,
        U.Usr_SSN,
        I.Ins_Salary,  -- Additional info if user is an instructor
        S.std_College,  -- Additional info if user is a student
        S.Track_ID, 
        T.Track_Name,  -- Missing comma added here
        S.Branch_ID,  -- Missing comma added here
        B.Branch_Loc
    FROM 
        USRS U
        LEFT JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID
        LEFT JOIN STUDENTS S ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN TRACKS T ON S.Track_ID = T.Track_ID
        INNER JOIN BRANCHES B ON B.Branch_ID = S.Branch_ID 
    WHERE
        @Usr_IDs IS NULL  -- No IDs provided, return all users
        OR U.Usr_ID IN (SELECT Usr_ID FROM @IDTable);  -- IDs provided, filter by them
END;
------------------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[InsertBranch]
    @Branch_Loc VARCHAR(100)
AS
BEGIN
    INSERT INTO BRANCHES (Branch_Loc)
    VALUES (@Branch_Loc);
END;
------------------
GO
ALTER PROCEDURE [dbo].[InsertCertificate]
    @Cer_Name VARCHAR(100)
AS
BEGIN
    -- Trim leading and trailing spaces
    SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));
    
    -- Check if the certificate already exists (case-insensitive)
    IF EXISTS (SELECT 1 FROM CERTIFICATES WHERE UPPER(LTRIM(RTRIM(Cer_Name))) = UPPER(@Cer_Name))
    BEGIN
        PRINT 'Certificate already exists.';
    END
    ELSE
    BEGIN
        -- Insert new certificate if it doesn't exist
        INSERT INTO CERTIFICATES (Cer_Name)
        VALUES (@Cer_Name);
        
        PRINT 'Certificate inserted successfully.';
    END
END;
------------------------------------------

GO
ALTER PROCEDURE [dbo].[InsertCourse]
    @Crs_Name VARCHAR(100),
    @Crs_Duration INT,
    @Topic_ID INT
AS
BEGIN
    INSERT INTO COURSES (Crs_Name, Crs_Duration, Topic_ID)
    VALUES (@Crs_Name, @Crs_Duration, @Topic_ID);
END;
------------------------------------------
GO
ALTER PROCEDURE [dbo].[InsertFreelancingJob]
    @FJ_JobTitle VARCHAR(100)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM FREELANCING_JOBS WHERE LTRIM(RTRIM(FJ_JobTitle)) = LTRIM(RTRIM(@FJ_JobTitle)))
    BEGIN
        PRINT 'Job title already exists.';
    END
    ELSE
    BEGIN
        INSERT INTO FREELANCING_JOBS (FJ_JobTitle)
        VALUES (LTRIM(RTRIM(@FJ_JobTitle)));
        PRINT 'Job added successfully.';
    END
END;
---------------------------
GO
ALTER PROCEDURE [dbo].[InsertInstructorQualification]
    @Ins_Usr_ID INT,
    @Ins_Qualification VARCHAR(100)
AS
BEGIN
    INSERT INTO INSTRUCTOR_QUALIFICATIONS (Ins_Usr_ID, Ins_Qualification)
    VALUES (@Ins_Usr_ID, @Ins_Qualification);
END;
---------------------------
GO
ALTER PROCEDURE [dbo].[InsertQuestionWithAnswers]
    @Q_Type INT,
    @Q_Text VARCHAR(500),
    @Q_CorrectAnswer VARCHAR(200),
    @Crs_ID INT,
    @AvailableAnswers VARCHAR(MAX)  -- Comma-separated list of answers
AS
BEGIN
    -- Insert the question
    INSERT INTO QUESTIONS (Q_Type, Q_Text, Q_CorrectAnswer, Crs_ID)
    VALUES (@Q_Type, @Q_Text, @Q_CorrectAnswer, @Crs_ID);

    -- Retrieve the last inserted Q_ID
    DECLARE @Q_ID INT;
    SET @Q_ID = SCOPE_IDENTITY();

    -- Split the available answers and insert them
    ;WITH SplitAnswers AS (
        SELECT value AS Q_AvailableAnswers
        FROM STRING_SPLIT(@AvailableAnswers, ',')
    )
    INSERT INTO QUESTIONS_AvailableAnswers (Q_ID, Q_AvailableAnswers)
    SELECT @Q_ID, Q_AvailableAnswers
    FROM SplitAnswers;
END;
---------------------------------
GO
ALTER PROCEDURE [dbo].[InsertStudentAnswer]
    @S_Usr_ID INT,          -- Student ID
    @Q_ID INT,              -- Question ID
    @Exam_ID INT,           -- Exam ID
    @Std_Answer VARCHAR(200) -- Student's answer
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Clean up the student answer input
        SET @Std_Answer = dbo.CollapsedSpaces(@Std_Answer);

        -- Check if the student exists
        IF NOT EXISTS (SELECT 1 FROM [STUDENTS] WHERE S_Usr_ID = @S_Usr_ID)
        BEGIN 
            -- Rollback the transaction if student does not exist
            PRINT 'Student does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the exam exists
        IF NOT EXISTS (SELECT 1 FROM [EXAMS] WHERE Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Exam with ID ' + CAST(@Exam_ID AS NVARCHAR) + ' does not exist.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Check if the question exists within the specified exam
        IF NOT EXISTS (SELECT 1 FROM [EXAM_GEN] WHERE Q_ID = @Q_ID AND Exam_ID = @Exam_ID)
        BEGIN
            PRINT 'Question with ID ' + CAST(@Q_ID AS NVARCHAR) + ' does not exist in Exam ID ' + CAST(@Exam_ID AS NVARCHAR) + '.';
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Insert the student's answer into STUDENT_ANSWERS table
        INSERT INTO [STUDENT_ANSWERS] (S_Usr_ID, Q_ID, Exam_ID, Std_Answer)
        VALUES (@S_Usr_ID, @Q_ID, @Exam_ID, @Std_Answer);

		

        -- Commit the transaction if the insert is successful
        COMMIT TRANSACTION;
        PRINT 'Student answer inserted successfully.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END;
------------------------------------------
GO
ALTER PROCEDURE [dbo].[InsertTopic]
    @Topic_Name VARCHAR(100)
AS
BEGIN
    INSERT INTO TOPICS (Topic_Name)
    VALUES (@Topic_Name);
END;
--------------------------------------------
GO
ALTER PROCEDURE [dbo].[InsertTrack]
    @Track_Name VARCHAR(100),
    @SV_Usr_ID INT = NULL
AS
BEGIN
    INSERT INTO TRACKS (Track_Name, SV_Usr_ID)
    VALUES (@Track_Name, @SV_Usr_ID);
END;
--------------------------------
GO
ALTER PROCEDURE [dbo].[InsertUser]
    @Usr_Fname VARCHAR(50),
    @Usr_Mname VARCHAR(50),
    @Usr_Lname VARCHAR(50),
    @Usr_Email VARCHAR(100),
    @Usr_Pass VARCHAR(256),  -- Accept password as a string
    @Usr_Phone VARCHAR(11),
    @Usr_DOB DATE,
    @Usr_City VARCHAR(50),
    @Usr_GOV VARCHAR(50),
    @Usr_Facebook VARCHAR(200),
    @Usr_LinkedIn VARCHAR(200),
    @Usr_Role VARCHAR(1),
    @Usr_Gender VARCHAR(1),
    @Usr_SSN VARCHAR(14),
    @Salary MONEY = NULL,  -- Optional parameter
    @College VARCHAR(100) = NULL
AS
BEGIN
    -- Hash the password and store it in a VARBINARY(256) variable
    DECLARE @HashedPass VARBINARY(256);
    SET @HashedPass = HASHBYTES('SHA2_256', @Usr_Pass);

    -- Insert into USRS table
    INSERT INTO USRS (
        Usr_Fname, Usr_Mname, Usr_Lname, Usr_Email, Usr_Pass, Usr_Phone, Usr_DOB, 
        Usr_City, Usr_GOV, Usr_Facebook, Usr_LinkedIn, Usr_Role, Usr_Gender, Usr_SSN
    )
    VALUES (
        @Usr_Fname, @Usr_Mname, @Usr_Lname, @Usr_Email, @HashedPass, @Usr_Phone, @Usr_DOB,
        @Usr_City, @Usr_GOV, @Usr_Facebook, @Usr_LinkedIn, @Usr_Role, @Usr_Gender, @Usr_SSN
    );

    -- Insert into INSTRUCTORS or STUDENTS table based on role
    IF @Usr_Role = 'I'
    BEGIN
        INSERT INTO INSTRUCTORS (Ins_Usr_ID, Ins_Salary)
        VALUES (SCOPE_IDENTITY(), @Salary);  -- Default salary if not provided
    END
    ELSE IF @Usr_Role = 'S'
    BEGIN
        INSERT INTO STUDENTS (S_Usr_ID, std_College)
        VALUES (SCOPE_IDENTITY(), @College);
    END
END;
----------------------------
GO
ALTER PROCEDURE [dbo].[InsertUsers]
    @Usr_Fname VARCHAR(50),
    @Usr_Mname VARCHAR(50),
    @Usr_Lname VARCHAR(50),
    @Usr_Email VARCHAR(100),
    @Usr_Pass VARCHAR(256),  -- Accept password as a string
    @Usr_Phone VARCHAR(11),
    @Usr_DOB DATE,
    @Usr_City VARCHAR(50),
    @Usr_GOV VARCHAR(50),
    @Usr_Facebook VARCHAR(200),
    @Usr_LinkedIn VARCHAR(200),
    @Usr_Role VARCHAR(1),
    @Usr_Gender VARCHAR(1),
    @Usr_SSN VARCHAR(14),
    @Salary MONEY = NULL,  -- Optional parameter for instructors
    @College VARCHAR(100) = NULL,  -- Optional parameter for students
    @TrackID INT = NULL,  -- Optional parameter for students
    @BranchID INT = NULL  -- Optional parameter for students
AS
BEGIN
    -- Hash the password and store it in a VARBINARY(256) variable
    DECLARE @HashedPass VARBINARY(256);
    SET @HashedPass = HASHBYTES('SHA2_256', @Usr_Pass);

    -- Insert into USRS table
    INSERT INTO USRS (
        Usr_Fname, Usr_Mname, Usr_Lname, Usr_Email, Usr_Pass, Usr_Phone, Usr_DOB, 
        Usr_City, Usr_GOV, Usr_Facebook, Usr_LinkedIn, Usr_Role, Usr_Gender, Usr_SSN
    )
    VALUES (
        @Usr_Fname, @Usr_Mname, @Usr_Lname, @Usr_Email, @HashedPass, @Usr_Phone, @Usr_DOB,
        @Usr_City, @Usr_GOV, @Usr_Facebook, @Usr_LinkedIn, @Usr_Role, @Usr_Gender, @Usr_SSN
    );

    -- Insert into INSTRUCTORS or STUDENTS table based on role
    IF @Usr_Role = 'I'
    BEGIN
        INSERT INTO INSTRUCTORS (Ins_Usr_ID, Ins_Salary)
        VALUES (SCOPE_IDENTITY(), @Salary);  -- Default salary if not provided
    END
    ELSE IF @Usr_Role = 'S'
    BEGIN
        INSERT INTO STUDENTS (S_Usr_ID, std_College, Track_ID, Branch_ID)
        VALUES (SCOPE_IDENTITY(), @College, @TrackID, @BranchID);
    END
END;
----------------------------------
GO
ALTER PROCEDURE [dbo].[InstructorCoursesAndNumOfStudents]
	@Ins_Usr_ID INT
AS
BEGIN 
	BEGIN TRANSACTION;
    BEGIN TRY
		-- Check Instructor's Existence
		IF NOT EXISTS ( SELECT 1 FROM INSTRUCTORS WHERE Ins_Usr_ID = @Ins_Usr_ID)
			BEGIN
				PRINT 'Instructor With ID : ' + CAST(@Ins_Usr_ID AS VARCHAR(10)) + ' does not exist.'
				ROLLBACK TRANSACTION ;
				RETURN;
			END
        -- Retrieve student course information if students exist
        SELECT
            C.Crs_Name, COUNT(SC.S_Usr_ID) AS NumberOfStudents
        FROM [USRS] U
        INNER JOIN INSTRUCTORS I ON U.Usr_ID = I.Ins_Usr_ID 
        INNER JOIN INSTRUCTOR_COURSES IC ON I.Ins_Usr_ID = IC.Ins_Usr_ID
        INNER JOIN [COURSES] C ON C.Crs_ID = IC.Crs_ID
		INNER JOIN STUDENT_COURSES SC ON C.Crs_ID = SC.Crs_ID
		WHERE I.Ins_Usr_ID = @Ins_Usr_ID
		GROUP BY C.Crs_Name

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END
--------------------------------------------
GO
ALTER proc [dbo].[re_topic_by_course] @crs_id int
as
begin
select c.Crs_Name,t.Topic_Name
from COURSES c
	inner join TOPICS t
	on t.Topic_ID=c.Topic_ID
where c.Crs_ID=@crs_id
end
Go

-----------------------------
ALTER PROCEDURE [dbo].[SelectCourses]
    @Crs_IDs NVARCHAR(MAX) = NULL  -- Accepts one or more IDs as a comma-separated string
AS
BEGIN
    IF @Crs_IDs IS NOT NULL
    BEGIN
        -- Split the comma-separated list into a table
        DECLARE @IDTable TABLE (Crs_ID INT);

        -- Insert the IDs into the temporary table
        INSERT INTO @IDTable (Crs_ID)
        SELECT CAST(value AS INT) FROM STRING_SPLIT(@Crs_IDs, ',');

        -- Select courses for the specified IDs
        SELECT * 
        FROM COURSES
        WHERE Crs_ID IN (SELECT Crs_ID FROM @IDTable);
    END
    ELSE
    BEGIN
        -- Select all courses if no IDs are provided
        SELECT * FROM COURSES;
    END
END;
-----------------------------------------------------
GO
ALTER PROCEDURE [dbo].[SelectInstructorQualifications]
    @Usr_IDs NVARCHAR(MAX) = NULL  -- Accepts one or more IDs as a comma-separated string
AS
BEGIN
    IF @Usr_IDs IS NOT NULL
    BEGIN
        -- Split the comma-separated list into a table
        DECLARE @IDTable TABLE (Usr_ID INT);

        -- Insert the IDs into the temporary table
        INSERT INTO @IDTable (Usr_ID)
        SELECT CAST(value AS INT) FROM STRING_SPLIT(@Usr_IDs, ',');

        -- Select qualifications for the specified IDs
        SELECT * 
        FROM INSTRUCTOR_QUALIFICATIONS
        WHERE Ins_Usr_ID IN (SELECT Usr_ID FROM @IDTable);
    END
    ELSE
    BEGIN
        -- Select all qualifications if no IDs are provided
        SELECT * FROM INSTRUCTOR_QUALIFICATIONS;
    END
END;
-------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[SelectTopics]
    @Topic_IDs NVARCHAR(MAX) = NULL  -- Accepts one or more IDs as a comma-separated string
AS
BEGIN
    IF @Topic_IDs IS NOT NULL
    BEGIN
        -- Split the comma-separated list into a table
        DECLARE @IDTable TABLE (Topic_ID INT);

        -- Insert the IDs into the temporary table
        INSERT INTO @IDTable (Topic_ID)
        SELECT CAST(value AS INT) FROM STRING_SPLIT(@Topic_IDs, ',');

        -- Select topics for the specified IDs
        SELECT * 
        FROM TOPICS
        WHERE Topic_ID IN (SELECT Topic_ID FROM @IDTable);
    END
    ELSE
    BEGIN
        -- Select all topics if no IDs are provided
        SELECT * FROM TOPICS;
    END
END;
--------------------------------------------
GO
ALTER PROCEDURE [dbo].[StudentGradeInAllCourses]
	@S_Usr_ID INT 
AS
BEGIN 
	BEGIN TRANSACTION;
    BEGIN TRY
		-- Check Student's Existence
		IF NOT EXISTS ( SELECT 1 FROM STUDENTS WHERE S_Usr_ID = @S_Usr_ID)
			BEGIN
				PRINT 'Student With ID : ' + CAST(@S_Usr_ID AS VARCHAR(10)) + ' does not exist.'
				ROLLBACK TRANSACTION ;
				RETURN;
			END
        -- Retrieve student course information if students exist
        SELECT
            S.S_Usr_ID,
            CONCAT_WS(' ', U.Usr_Fname, U.Usr_Mname, U.Usr_Lname) AS StudentName,
            C.Crs_ID,
            C.Crs_Name, 
			SC.Grade
        FROM [USRS] U
        INNER JOIN [STUDENTS] S ON U.Usr_ID = S.S_Usr_ID
        INNER JOIN [STUDENT_COURSES] SC ON S.S_Usr_ID = SC.S_Usr_ID
        INNER JOIN [COURSES] C ON SC.Crs_ID = C.Crs_ID
		WHERE S.S_Usr_ID = @S_Usr_ID

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        PRINT 'Error occurred: ' + @ErrorMessage;
        
        -- Rethrow the error and rollback
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
        ROLLBACK TRANSACTION;
    END CATCH
END

-----------------------------------
GO
ALTER PROCEDURE [dbo].[TopicByCourse]
	@Crs_IDs NVARCHAR(MAX) = NULL 
AS
BEGIN 
	BEGIN TRANSACTION;
    BEGIN TRY
        -- Trim leading and trailing spaces from the input parameter
        SET @Crs_IDs = dbo.RemoveAllSpaces(@Crs_IDs);

        IF @Crs_IDs IS NOT NULL
        BEGIN
            -- Create a temporary table to store the course names
            DECLARE @NameTable TABLE (Crs_ID INT);

            -- Insert the names into the temporary table
            INSERT INTO @NameTable (Crs_ID)
            SELECT CAST(value AS INT) FROM STRING_SPLIT(@Crs_IDs, ',');

            -- Check if any courses match the provided IDs
            IF EXISTS (
			(
                SELECT 1
                FROM [COURSES] c
                JOIN @NameTable nt ON C.Crs_ID = nt.Crs_ID )
            )
            BEGIN
                -- Select courses for the provided names
                SELECT C.Crs_ID , C.Crs_Name , T.Topic_Name
                FROM [COURSES] c
                JOIN @NameTable nt ON C.Crs_ID = nt.Crs_ID
				INNER JOIN TOPICS T 
					ON T.Topic_ID = C.Topic_ID
				ORDER BY T.Topic_Name ;
                
                PRINT 'Courses displayed successfully.';
            END
            ELSE
            BEGIN
                -- No courses found for the provided names
                PRINT 'No courses found for the provided IDs.';
                ROLLBACK TRANSACTION;
                RETURN;
            END
        END
        ELSE
        BEGIN
            -- Select all courses if no names are provided
            SELECT C.Crs_ID, C.Crs_Name , T.Topic_Name 
			FROM [COURSES] C
			INNER JOIN TOPICS T
				ON T.Topic_ID = C.Topic_ID 
			ORDER BY T.Topic_Name;
            PRINT 'All courses displayed successfully.';
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Handle errors
        ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Print error message
        PRINT 'Error occurred: ' + @ErrorMessage;

        -- Rethrow the error
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END

---------------------------------------
GO
ALTER PROCEDURE [dbo].[UnassignCourseFromTrack]
    @Track_ID INT,
    @Crs_ID INT
AS
BEGIN
    -- Delete the course from the track
    DELETE FROM TRACKS_COURSES
    WHERE Track_ID = @Track_ID AND Crs_ID = @Crs_ID;
END;
-----------------------------------
GO

ALTER PROCEDURE [dbo].[UnassignInstructorFromCourse]
    @Ins_Usr_ID INT,
    @Crs_ID INT
AS
BEGIN
    -- Delete the assignment from the INSTRUCTOR_COURSES table
    DELETE FROM INSTRUCTOR_COURSES
    WHERE Ins_Usr_ID = @Ins_Usr_ID
    AND Crs_ID = @Crs_ID;
END;
---------------------------
GO
ALTER PROCEDURE [dbo].[UnassignStudentFromCertificate]
    @S_Usr_ID INT,
    @Cer_ID INT
AS
BEGIN
    -- Check if the student is assigned to the certificate
    IF EXISTS (SELECT 1 FROM STUDENT_CERTIFICATES WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID)
    BEGIN
        -- If the assignment exists, delete it
        DELETE FROM STUDENT_CERTIFICATES WHERE S_Usr_ID = @S_Usr_ID AND Cer_ID = @Cer_ID;
        PRINT 'Student unassigned from the certificate successfully.';
    END
    ELSE
    BEGIN
        -- If the assignment doesn't exist, print a message
        PRINT 'The student is not assigned to this certificate.';
    END
END;
-------------------------------------------
GO
ALTER PROCEDURE [dbo].[UnassignStudentFromCourse]
    @Std_IDs VARCHAR(MAX),  -- Comma-separated list of student IDs
    @Crs_ID INT  -- Course ID from which students will be unassigned
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Split the list of student IDs into a table variable
        DECLARE @StudentList TABLE (S_Usr_ID INT);

        INSERT INTO @StudentList (S_Usr_ID)
        SELECT value
        FROM STRING_SPLIT(@Std_IDs, ',');

        -- Delete from STUDENT_COURSES table
        DELETE FROM STUDENT_COURSES
        WHERE S_Usr_ID IN (SELECT S_Usr_ID FROM @StudentList)
        AND Crs_ID = @Crs_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;
---------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UnassignStudentFromJob]
    @S_Usr_ID INT,
    @FJ_JobTitle VARCHAR(100)
AS
BEGIN
    DECLARE @FJ_ID INT;

    -- Check if the student ID exists in the STUDENTS table
    IF NOT EXISTS (SELECT 1 FROM STUDENTS WHERE S_Usr_ID = @S_Usr_ID)
    BEGIN
        PRINT 'Student ID does not exist.';
        RETURN;
    END

    -- Check if the job title exists in the FREELANCING_JOBS table
    SELECT @FJ_ID = FJ_ID
    FROM FREELANCING_JOBS
    WHERE LTRIM(RTRIM(FJ_JobTitle)) = LTRIM(RTRIM(@FJ_JobTitle));

    -- If job title exists, delete the student-job relation
    IF @FJ_ID IS NOT NULL
    BEGIN
        DELETE FROM STUDENT_JOBS
        WHERE S_Usr_ID = @S_Usr_ID AND FJ_ID = @FJ_ID;

        IF @@ROWCOUNT > 0
        BEGIN
            PRINT 'Student unassigned from the job successfully.';
        END
        ELSE
        BEGIN
            PRINT 'No matching record found for the student and job.';
        END
    END
    ELSE
    BEGIN
        PRINT 'Job title does not exist.';
    END
END;
   
----------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UnassignStudentFromTrackAndBranch]
    @Std_IDs VARCHAR(MAX)  -- Comma-separated list of student IDs
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Split the list of student IDs and update their Track_ID and Branch_ID to NULL
        ;WITH StudentList AS (
            SELECT value AS S_Usr_ID
            FROM STRING_SPLIT(@Std_IDs, ',')
        )
        UPDATE STUDENTS
        SET Track_ID = NULL,
            Branch_ID = NULL
        FROM STUDENTS S
        INNER JOIN StudentList SL
        ON S.S_Usr_ID = SL.S_Usr_ID;

        -- Commit the transaction if all operations succeed
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback the transaction if an error occurs
        ROLLBACK TRANSACTION;

        -- Optionally, raise an error message
        THROW;
    END CATCH;
END;

--------------------------------------------
GO
ALTER PROCEDURE [dbo].[UnassignTrackFromBranch]
    @Branch_ID INT,
    @Track_ID INT
AS
BEGIN
    DELETE FROM BRANCHES_TRACKS
    WHERE Branch_ID = @Branch_ID
    AND Track_ID = @Track_ID;
END;
------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateBranch]
    @Branch_ID INT,
    @Branch_Loc VARCHAR(100) = NULL
AS
BEGIN
    UPDATE BRANCHES
    SET Branch_Loc = COALESCE(@Branch_Loc, Branch_Loc)
    WHERE Branch_ID = @Branch_ID;
END;
---------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateCertificate]
    @Cer_ID INT,
    @Cer_Name VARCHAR(100)
AS
BEGIN
    -- Trim leading and trailing spaces
    SET @Cer_Name = LTRIM(RTRIM(@Cer_Name));
	IF EXISTS (SELECT 1 FROM CERTIFICATES WHERE UPPER(LTRIM(RTRIM(Cer_Name))) = UPPER(@Cer_Name))
    BEGIN
		PRINT 'Certificate already exists'
	END
	ELSE
	BEGIN
		UPDATE CERTIFICATES
		SET Cer_Name = @Cer_Name
		WHERE Cer_ID = @Cer_ID;
		PRINT 'Certificate Updated Successfully'
	END
END;
------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateCourse]
    @Crs_ID INT,  -- This is mandatory as it's the primary key
    @New_Crs_Name VARCHAR(100) = NULL,
    @New_Crs_Duration INT = NULL,
    @New_Topic_ID INT = NULL
AS
BEGIN
    UPDATE COURSES
    SET 
        Crs_Name = COALESCE(@New_Crs_Name, Crs_Name),  -- If NULL, keep the current value
        Crs_Duration = COALESCE(@New_Crs_Duration, Crs_Duration),  -- If NULL, keep the current value
        Topic_ID = COALESCE(@New_Topic_ID, Topic_ID)  -- If NULL, keep the current value
    WHERE Crs_ID = @Crs_ID;
END;
------------------------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateFreelancingJob]
    @FJ_ID INT,
    @FJ_JobTitle VARCHAR(100)
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM FREELANCING_JOBS WHERE FJ_ID = @FJ_ID)
    BEGIN
        PRINT 'Job ID does not exist.';
    END
    ELSE IF EXISTS (SELECT 1 FROM FREELANCING_JOBS WHERE LTRIM(RTRIM(FJ_JobTitle)) = LTRIM(RTRIM(@FJ_JobTitle)) AND FJ_ID <> @FJ_ID)
    BEGIN
        PRINT 'Another job with the same title exists (ignoring spaces).';
    END
    ELSE
    BEGIN
        UPDATE FREELANCING_JOBS
        SET FJ_JobTitle = LTRIM(RTRIM(@FJ_JobTitle))
        WHERE FJ_ID = @FJ_ID;
        PRINT 'Job updated successfully.';
    END
END;
----------------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateInstructorQualification]
    @Ins_Usr_ID INT,
    @Old_Qualification VARCHAR(100),
    @New_Qualification VARCHAR(100)
AS
BEGIN
    UPDATE INSTRUCTOR_QUALIFICATIONS
    SET Ins_Qualification = @New_Qualification
    WHERE Ins_Usr_ID = @Ins_Usr_ID
    AND Ins_Qualification = @Old_Qualification;
END;
---------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateQuestionWithAnswers]
    @Q_ID INT,
    @Q_Type INT = NULL,  -- Optional parameter
    @Q_Text VARCHAR(500) = NULL,  -- Optional parameter
    @Q_CorrectAnswer VARCHAR(200) = NULL,  -- Optional parameter
    @Crs_ID INT = NULL,  -- Optional parameter
    @AvailableAnswers VARCHAR(MAX) = NULL  -- Optional parameter
AS
BEGIN
    -- Update the question if parameters are not NULL
    UPDATE QUESTIONS
    SET 
        Q_Type = COALESCE(@Q_Type, Q_Type),
        Q_Text = COALESCE(@Q_Text, Q_Text),
        Q_CorrectAnswer = COALESCE(@Q_CorrectAnswer, Q_CorrectAnswer),
        Crs_ID = COALESCE(@Crs_ID, Crs_ID)
    WHERE Q_ID = @Q_ID;

    -- If AvailableAnswers is provided, update available answers
    IF @AvailableAnswers IS NOT NULL
    BEGIN
        -- Delete existing available answers
        DELETE FROM QUESTIONS_AvailableAnswers
        WHERE Q_ID = @Q_ID;

        -- Split the available answers and insert them
        ;WITH SplitAnswers AS (
            SELECT LTRIM(RTRIM(value)) AS Q_AvailableAnswers  -- Trim spaces
            FROM STRING_SPLIT(@AvailableAnswers, ',')
            WHERE LTRIM(RTRIM(value)) <> ''  -- Exclude empty values
        )
        INSERT INTO QUESTIONS_AvailableAnswers (Q_ID, Q_AvailableAnswers)
        SELECT @Q_ID, Q_AvailableAnswers
        FROM SplitAnswers;
    END
END;
--------------------------------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateTopic]
    @Topic_ID INT,
    @New_Topic_Name VARCHAR(100)
AS
BEGIN
    UPDATE TOPICS
    SET Topic_Name = @New_Topic_Name
    WHERE Topic_ID = @Topic_ID;
END;
------------------------------------
GO
ALTER PROCEDURE [dbo].[UpdateTrack]
    @Track_ID INT,
    @Track_Name VARCHAR(100) = NULL,
    @SV_Usr_ID INT = NULL
AS
BEGIN
    UPDATE TRACKS
    SET Track_Name = COALESCE(@Track_Name, Track_Name),
        SV_Usr_ID = COALESCE(@SV_Usr_ID, SV_Usr_ID)
    WHERE Track_ID = @Track_ID;
END;
------------------------------------------------
GO
/*
2- Update User Procedure :
take the info that will be updated , and depend on his\her role 
, it will update the info of this role
*/
ALTER PROCEDURE [dbo].[UpdateUser]
    @Usr_ID INT,  -- Required parameter to identify the record to update
    @Usr_Fname VARCHAR(50) = NULL,
    @Usr_Mname VARCHAR(50) = NULL,
    @Usr_Lname VARCHAR(50) = NULL,
    @Usr_Email VARCHAR(100) = NULL,
    @Usr_Pass VARCHAR(256) = NULL,  -- Password will be hashed inside the procedure
    @Usr_Phone VARCHAR(11) = NULL,
    @Usr_DOB DATE = NULL,
    @Usr_City VARCHAR(50) = NULL,
    @Usr_GOV VARCHAR(50) = NULL,
    @Usr_Facebook VARCHAR(200) = NULL,
    @Usr_LinkedIn VARCHAR(200) = NULL,
    @Usr_Role VARCHAR(1) = NULL,
    @Usr_Gender VARCHAR(1) = NULL,
    @Usr_SSN VARCHAR(14) = NULL,
    @Salary MONEY = NULL,  -- Optional parameter for Instructor salary
    @College VARCHAR(100) = NULL  -- Optional parameter for Student college
AS
BEGIN
    -- Update the USRS table only with the provided values
    UPDATE USRS
    SET
        Usr_Fname = COALESCE(@Usr_Fname, Usr_Fname),
        Usr_Mname = COALESCE(@Usr_Mname, Usr_Mname),
        Usr_Lname = COALESCE(@Usr_Lname, Usr_Lname),
        Usr_Email = COALESCE(@Usr_Email, Usr_Email),
        Usr_Pass = COALESCE(
            CASE 
                WHEN @Usr_Pass IS NOT NULL THEN HASHBYTES('SHA2_256', @Usr_Pass)
                ELSE Usr_Pass 
            END, 
            Usr_Pass
        ),
        Usr_Phone = COALESCE(@Usr_Phone, Usr_Phone),
        Usr_DOB = COALESCE(@Usr_DOB, Usr_DOB),
        Usr_City = COALESCE(@Usr_City, Usr_City),
        Usr_GOV = COALESCE(@Usr_GOV, Usr_GOV),
        Usr_Facebook = COALESCE(@Usr_Facebook, Usr_Facebook),
        Usr_LinkedIn = COALESCE(@Usr_LinkedIn, Usr_LinkedIn),
        Usr_Role = COALESCE(@Usr_Role, Usr_Role),
        Usr_Gender = COALESCE(@Usr_Gender, Usr_Gender),
        Usr_SSN = COALESCE(@Usr_SSN, Usr_SSN)
    WHERE Usr_ID = @Usr_ID;

    -- Update the INSTRUCTORS table if the user is an Instructor and Salary is provided
    IF EXISTS (SELECT 1 FROM INSTRUCTORS WHERE Ins_Usr_ID = @Usr_ID)
    BEGIN
        UPDATE INSTRUCTORS
        SET
            Ins_Salary = COALESCE(@Salary, Ins_Salary)
        WHERE Ins_Usr_ID = @Usr_ID;
    END

    -- Update the STUDENTS table if the user is a Student and College is provided
    IF EXISTS (SELECT 1 FROM STUDENTS WHERE S_Usr_ID = @Usr_ID)
    BEGIN
        UPDATE STUDENTS
        SET
            std_College = COALESCE(@College, std_College)
        WHERE S_Usr_ID = @Usr_ID;
    END
END;
------------------------------------------------


