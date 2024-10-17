# ITI_Examination_System 
Graduation Project At ITI(information technology institute) for Track Business Intelligence Development
## Table of Content:
1- [Introduction](#introduction) <br>
2- [Business Requirements](#bussiness-requirements) <br>
3- [ERD](#erd) <br>
4- [Mapping](#mapping) <br>
5- [Database-Structure](#database-structure-and-design-overview) <br>
6- [Stored-Procedures](#stored-procedures) <br>
7- [Reports](#reports)<br>
8- [PowerBi-Dashboards](#powerbi-dashboard)<br>
9- [Contributors](#contributors)

## Introduction
To complete graduation from ITI Bussiness Intelligenece Track we've built from scratch the examination system from requirement documents,and Create ERD diagram ,and mapping ERD to acutal tables and Creating whole database, we implement the stored procedures to generate the exam and for every other task like DML Commands  and for auto correction of exams ,and for for generating Reports all have been built using stored procedures.<br>
after building the database we enrich the data then generating reports and dashboards.
## Bussiness Requirements
This Document describes the bussiness requirements for building the examination system to be utilized for ERD which will be later transformed to ERD.<br>
for more info please go to [required documents](required_document.pdf)

## ERD
This contains entity relationship diagram (ERD) after gathering the bussiness Requirments to facilitate the mapping here's the ERD ,and also we've implemented Enhanced ERD (EERD)  <br>
for more info please go to [System ERD](./System_ERD.pdf)


## Mapping
After Creation of ERD then Mapping to transform the diagram to actual tables <br>
for more info please go to [System Mapping](System_Mapping.pdf)

## Database Structure and Design Overview
This the  database structure and final Diagram that's shows relationships between tables <br>
![image](https://github.com/user-attachments/assets/a184dc44-1034-4130-b8c8-4545734e4483)<br>

![image](https://github.com/user-attachments/assets/68cd77f2-5058-4f10-9779-62ccb3f2078a) <br>

Final Diagram

![image](https://github.com/user-attachments/assets/e447ab8e-db68-4f06-8e34-3e07ae93be00)  <br>




## Stored Procedures 
we've implemented many stored procedures to cover most of the system needs and to generate exams which every exam contains random questions,and also to generate the reports ,here's quick overview for stored procedures <br>
but if you want the full code of all stored procedures please go to [All Stored Procedures](./All_stored_procedures.sql) <br>
Note: if you want to try these stored procedures please download the full database backup and restore it [Full DataBase Backup](./System_DB.bak)(Microsoft SQL Server 2022) which contains the whole system 


![image](https://github.com/user-attachments/assets/3a965a47-a87a-4310-9029-535c12df6cd4) <br>

![image](https://github.com/user-attachments/assets/efb6cc3c-399e-41f5-a040-11f5ea692033) <br>

![image](https://github.com/user-attachments/assets/8f01bdad-77e8-4d5e-a708-efccbb89ffb5)  <br>

![image](https://github.com/user-attachments/assets/bf3f5a83-62af-48bb-95f4-9f567d1fee9c)  <br>

![image](https://github.com/user-attachments/assets/af11f8b8-64b4-4b17-889e-e784e6bd98cd)  <br>



## Reports 
these reports generated from Stored Procedures  through PowerBi Report Builder <br>
for full report please go to [All Reports](./Reports)

## PowerBi Dashboard
Here's Some of the Dashboards that's been implemented through the  Examination system  using  power Bi<br>

![image](https://github.com/user-attachments/assets/0688ba43-fc70-4b01-bc88-6216f3d4a51c)

![image](https://github.com/user-attachments/assets/c7645070-af12-431b-b38f-d7f7539640c4)

![image](https://github.com/user-attachments/assets/6cdf77e6-a852-46bf-82a7-dd724e8d7708)



## Contributors 
This Project is a Team effort of 5 members. <br> Our Team Members Are: <br>
1-Islam Mohamed (Myself)<br>
2-Ahmed Negm <br>
3-Abdallah Hamady <br>
4-Esraa Morsy <br>
5-Omar Nafea <br>
