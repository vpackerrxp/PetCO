page 80016 "PC Purch. Order Exceptions"
{
    Caption = 'Purchase Order Exceptions';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Purch Exceptions";
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = True;
   
    layout
    {
        area(Content)
        {
            group(Log)
            {
                Visible = Not DispMode;
                Field("";'Job Queue Info')
                {
                    ApplicationArea = All;
                    ShowCaption = false;
                    Style = Strong;
                    trigger OnDrillDown()
                    var
                        JQELog:record "Job Queue Log Entry";
                        Pg:Page "Job Queue Log Entries";
                        JQE:record "Job queue entry";
                        Pg2:page "Job Queue Entry Card";
                    begin
                        Case StrMenu('Show Logs,Show Card,Show Final Status',1) of
                            1:
                                begin
                                    JqElog.Reset;
                                    Jqelog.Setrange("Object Type to Run",JqElog."Object Type to Run"::Codeunit);
                                    Jqelog.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
                                    If jqelog.findset then
                                    begin
                                        Pg.SetTableView(Jqelog);
                                        Pg.RunModal();
                                    end;
                                end;
                            2:        
                                begin
                                    JqE.Reset;
                                    Jqe.Setrange("Object Type to Run",JqE."Object Type to Run"::Codeunit);
                                    Jqe.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
                                    If jqe.findset then
                                    begin
                                        Pg2.SetTableView(Jqe);
                                        Pg2.RunModal();
                                    end;
                                end;
                            3:
                                begin;
                                    JqElog.Reset;
                                    Jqelog.Setrange("Object Type to Run",JqElog."Object Type to Run"::Codeunit);
                                    Jqelog.setrange("Object ID to Run",Codeunit::"PC EDI Routines");
                                    If jqelog.findlast then Message('Final Run Status = %1',Jqelog.Status);
                                end;    
                        end;
                    end;    
                }
            }
           repeater(Group)
            {
                field("Exception Date";rec."Exception Date")
                {
                    ApplicationArea = All;
                }
                 field("Purchase Order No.";rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PuchHdr:record "Purchase Header";
                        pg:Page "Purchase Order";
                    begin
                        If PuchHdr.Get(PuchHdr."Document Type"::Order,rec."Purchase Order No.") then
                        begin
                            Pg.SetRecord(PuchHdr);
                            Pg.RunModal();
                            CurrPage.update(false);
                       end;
                    end;
                }
                field("Exception Qty Counts";rec."Exception Count")
                {
                    ApplicationArea = All;
                    Visible = DispMode;
                }
                field("Not On Order Exception Count";rec."Not On Order Exception Count")
                {
                    ApplicationArea = All;
                    Visible = DispMode;
                }
                field("Unknown SKU Exception Count";rec."Unknown SKU Exception Count")
                {
                    ApplicationArea = All;
                    Visible = DispMode;
                }
                field("EDI Exception Messages";rec."EDI Exception Messages")
                {
                    ApplicationArea = All;
                    Visible = Not DispMode;
                    Editable = false;
                    trigger OnDrillDown()
                    var
                        Excp:Record "PC EDI Exception Messages";
                        pg:page "PC EDI Exceptions";
                    begin
                        Excp.Reset();
                        Excp.setrange("Purchase Order No.",rec."Purchase Order No.");
                        If Excp.findset then
                        begin
                            pg.SetTableView(Excp);
                            pg.RunModal();
                        end;
                        CurrPage.Update(False);    
                    end;
                }
            }
        }
    }
 
    Procedure Set_Display_Mode(mode:Boolean)
    begin
        DispMode := Mode;
    end;
    var
        DispMode:Boolean;
}