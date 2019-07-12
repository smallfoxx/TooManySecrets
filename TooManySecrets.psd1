
@{                      
    NestedModules       =  @( 
							"Whistler.psm1",
							"Mother.psm1"
						  )

    #This GUID was generated on 7/11/2019
	GUID                = '426237eb-1a68-4db9-a10c-b8206698c3d3'

    Author              = "Kit Skinner"

    CompanyName         = "SmallFoxx"  #NOT Affiliated with Setec Astronomy
 
    Copyright           = "© 2019 Kit Skinner. All rights reserved."

    ModuleVersion       = "0.0.1"

    PowerShellVersion   = "4.0"

    CLRVersion          = "4.0"

    RequiredModules     = @(
                            @{ModuleName="Az.Accounts";ModuleVersion="1.5.3";GUID="17a2feff-488b-47f9-8729-e2cec094624c"},
<#                            @{ModuleName="Az.Aks";ModuleVersion="1.0.1";GUID="a97e0c3e-e389-46a6-b73d-2b9bd6909bdb"},
                            @{ModuleName="Az.AnalysisServices";ModuleVersion="1.1.0";GUID="d4877565-4778-42de-b494-79491ab9c31c"},
                            @{ModuleName="Az.ApiManagement";ModuleVersion="1.1.0";GUID="4f58d643-631f-4d13-a205-15292af40748"},
                            @{ModuleName="Az.ApplicationInsights";ModuleVersion="1.0.0";GUID="e3077f56-10b0-4190-a07f-3f1e454e3a42"},
                            @{ModuleName="Az.Automation";ModuleVersion="1.2.2";GUID="ef36c942-4a71-4e19-9450-05a35843deb6"},
                            @{ModuleName="Az.Batch";ModuleVersion="1.1.0";GUID="c6da7084-6a9c-4c33-b162-0f2c6bfad401"},
                            @{ModuleName="Az.Billing";ModuleVersion="1.0.0";GUID="c59978aa-69f9-401a-bbdc-5c9f8286aa4f"},
                            @{ModuleName="Az.Cdn";ModuleVersion="1.3.0";GUID="91832aaa-dc11-4583-8239-bce5fd531604"},
                            @{ModuleName="Az.CognitiveServices";ModuleVersion="1.1.1";GUID="492308f7-25bf-4606-888f-357c7c2850aa"},
                            @{ModuleName="Az.Compute";ModuleVersion="2.3.0";GUID="d4cb9989-9ed1-49c2-bacd-0f8daf758671"},
                            @{ModuleName="Az.ContainerInstance";ModuleVersion="1.0.1";GUID="4c06e8d3-d64f-4497-8574-16e0c9dfebb2"},
                            @{ModuleName="Az.ContainerRegistry";ModuleVersion="1.0.1";GUID="11a1f96b-f261-4be1-8e1e-1613eedddacc"},
                            @{ModuleName="Az.DataFactory";ModuleVersion="1.1.1";GUID="e3c0f6bc-fe96-41a0-88f4-5e490a91f05d"},
                            @{ModuleName="Az.DataLakeAnalytics";ModuleVersion="1.0.0";GUID="89eceb4f-9916-4ec5-8499-d5cca97a9cae"},
                            @{ModuleName="Az.DataLakeStore";ModuleVersion="1.2.1";GUID="3fabfb08-d284-44b8-a982-eaada389075e"},
                            @{ModuleName="Az.DeploymentManager";ModuleVersion="1.0.0";GUID="caac1590-e859-444f-a9e0-62091c0f5929"},
                            @{ModuleName="Az.DevTestLabs";ModuleVersion="1.0.0";GUID="272a9e53-defc-4e25-af4d-122bd41ad458"},
                            @{ModuleName="Az.Dns";ModuleVersion="1.1.1";GUID="f9850afe-b631-4369-ab61-eca7023f2f42"},
                            @{ModuleName="Az.EventGrid";ModuleVersion="1.2.0";GUID="d2167b29-9406-4ec7-b089-500460b3ebbd"},
                            @{ModuleName="Az.EventHub";ModuleVersion="1.2.0";GUID="d1fc588c-f6f1-4c18-968b-94c7c1ee695d"},
                            @{ModuleName="Az.FrontDoor";ModuleVersion="1.1.0";GUID="91832aaa-dc11-4583-8239-adb7df531604"},
                            @{ModuleName="Az.HDInsight";ModuleVersion="2.0.0";GUID="483c408e-6d98-45fc-b138-5b2327216d16"},
                            @{ModuleName="Az.IotHub";ModuleVersion="1.1.0";GUID="888ad48f-0bd0-4141-80fd-ecaae40d3923"},
                            @{ModuleName="Az.LogicApp";ModuleVersion="1.2.1";GUID="e1e65791-bedc-446d-9d9e-61c544dda1ae"},
                            @{ModuleName="Az.MachineLearning";ModuleVersion="1.1.0";GUID="287cb4af-0379-4154-86bf-63c34f734bd3"},
                            @{ModuleName="Az.MarketplaceOrdering";ModuleVersion="1.0.0";GUID="95b51ba9-b0c9-430e-bab9-69492bc277cf"},
                            @{ModuleName="Az.Media";ModuleVersion="1.1.0";GUID="c7f9ca6c-ada2-4df8-9cae-8b91f9e899c2"},
                            @{ModuleName="Az.Monitor";ModuleVersion="1.2.1";GUID="bc723b54-a697-44a2-9c48-d5749b138d1a"},
                            @{ModuleName="Az.Network";ModuleVersion="1.10.0";GUID="f554cfcd-9cbb-4021-b158-fe20f0497f82"},
                            @{ModuleName="Az.NotificationHubs";ModuleVersion="1.1.0";GUID="403ef21f-1a49-4de6-8ef3-9a79240cde32"},
                            @{ModuleName="Az.OperationalInsights";ModuleVersion="1.3.0";GUID="c0fd6ad6-f349-46a5-a57b-4e8aa07544a0"},
                            @{ModuleName="Az.PolicyInsights";ModuleVersion="1.1.1";GUID="8e5143cc-e222-4c80-9e62-c87989326174"},
                            @{ModuleName="Az.PowerBIEmbedded";ModuleVersion="1.1.0";GUID="b45b352f-17bd-465e-b162-10724c318e14"},
                            @{ModuleName="Az.RecoveryServices";ModuleVersion="1.4.1";GUID="5af71f43-17ca-45bd-b534-34524b801ade"},
                            @{ModuleName="Az.RedisCache";ModuleVersion="1.1.0";GUID="66466448-cfe3-4897-9956-b37a536c1603"},
                            @{ModuleName="Az.Relay";ModuleVersion="1.0.1";GUID="668e7be1-9801-496f-a7ed-25b1077d2f23"},
                            @{ModuleName="Az.Resources";ModuleVersion="1.5.0";GUID="48bb344d-4c24-441e-8ea0-589947784700"},
                            @{ModuleName="Az.ServiceBus";ModuleVersion="1.2.0";GUID="ced192ca-b6cd-4848-90dc-b83a5970befc"},
                            @{ModuleName="Az.ServiceFabric";ModuleVersion="1.1.1";GUID="f98e4fc9-6247-4e59-99a1-7b8ba13b3d1e"},
                            @{ModuleName="Az.SignalR";ModuleVersion="1.0.2";GUID="a97e0c3e-e389-46a6-b73d-2b9bd6909bdb"},
                            @{ModuleName="Az.Sql";ModuleVersion="1.12.0";GUID="f088f4ab-1b59-4836-a6e0-4e14d15800c6"},  
                            @{ModuleName="Az.StreamAnalytics";ModuleVersion="1.0.0";GUID="1fb42c21-81b6-4b14-af67-ad21f7867cd7"},
                            @{ModuleName="Az.TrafficManager";ModuleVersion="1.0.1";GUID="fe9266bb-89fe-4eb4-a63a-cbefad974666"},
                            @{ModuleName="Az.Websites";ModuleVersion="1.3.0";GUID="80c60f49-dd83-4f4e-92ad-5f3449de36e3"} #>
                            @{ModuleName="Az.KeyVault";ModuleVersion="1.2.0";GUID="cd188042-f215-4657-adfe-c17ae28cf730"},
                            @{ModuleName="Az.Storage";ModuleVersion="1.4.0";GUID="dfa9e4ea-1407-446d-9111-79122977ab20"}
                        )

}

