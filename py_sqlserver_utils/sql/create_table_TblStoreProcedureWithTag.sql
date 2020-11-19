USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[TblStoreProcedureWithTag](
	[DatabaseName] [varchar](100) NOT NULL,
	[ObjectId] [bigint] NULL,
	[SchemaName] [varchar](50) NULL,
	[ObjectName] [varchar](500) NOT NULL,
	[String_TaggingRank] [int] NOT NULL,
	[String_Tagging] [varchar](2000) NULL,
	[DateModify] [datetime] NULL,
 CONSTRAINT [PK_TblStoreProcedureWithTag] PRIMARY KEY CLUSTERED 
(
	[DatabaseName] ASC,
	[ObjectName] ASC,
	[String_TaggingRank] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
