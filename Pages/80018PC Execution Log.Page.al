page 80018 "PC Execution Log"
{
    Caption = 'Execution Log ';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = "PC Execution Log";
    SourceTableView = order(descending); 
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    
    layout
    {
        area(Content)
        {
            group(Filters)
            {
                field("Execution Date Filter"; ExDate)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Exdate);
                        Setfilters      
                    end;
                }    
                field("Status Filter"; Stat)
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    begin
                        SetFilters();
                    end;
                    trigger OnAssistEdit()
                    begin
                        Clear(Stat);
                        Setfilters      
                    end;
                }
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
                                    Jqelog.setrange("Object ID to Run",Codeunit::"PC Shopify Routines");
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
                                    Jqe.setrange("Object ID to Run",Codeunit::"PC Shopify Routines");
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
                                    Jqelog.setrange("Object ID to Run",Codeunit::"PC Shopify Routines");
                                    If jqelog.findlast then Message('Final Run Status = %1',Jqelog.Status);
                                end;    
                        end;
                    end;    
                }
                Group(Removals)
                {
                    field("Msg1";'Remove Entries Older Than 7 Days')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        trigger OnDrillDown()
                        var 
                        begin
                            If confirm(StrSubstNo('Remove all Records < %1 Now?',CalcDate('-7D',Today)),True) then
                            begin
                                Rec.Reset;
                                Rec.Setfilter("Execution Time",'<%1',CreateDateTime(CalcDate('-7D',Today),000000T));
                                If Rec.findset then Rec.DeleteAll();
                                SetFilters();
                            end;
                        end;
                    }
                    field("MSG2";'Remove All Entries')
                    {
                        ApplicationArea = All;
                        ShowCaption = false;
                        Style = Strong;
                        trigger OnDrillDown()
                        var 
                        begin
                            If confirm('Remove all Records Now?',True) then
                            begin
                                Rec.Reset;
                                If Rec.findset then Rec.DeleteAll();
                                SetFilters();
                            end;
                        end;
                    }
                }
            }    
            repeater(Group)
            {
                field("Execution Start Time"; rec."Execution Start Time")
                {
                    ApplicationArea = All;
                    Caption = 'Execution Start Time';
                }
                field("Execution Time"; rec."Execution Time")
                {
                    ApplicationArea = All;
                    Caption = 'Execution End Time';
                }
                field(Operation; rec.Operation)
                {
                    ApplicationArea = All;
                }
                field("Error Message"; rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field(Status; rec.Status)
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        pg:page "PC Shopify Update Log";
                    begin
                        If (Rec.Operation.ToUpper() = 'SYNCHRONISE SHOPIFY ITEMS')  AND (Rec.Status = rec.Status::Fail) then
                            pg.RunModal(); 
                        CurrPage.update(false);
                    end;    
                }
            }
        }
    }
    local procedure SetFilters()
    var
    begin
        rec.Reset;
        rec.SetAscending(ID,false);
        if Exdate <> 0D then
             rec.SetRange("Execution Start Time",CreateDateTime(Exdate,000000T),CreateDateTime(Exdate,235959T));
        If Stat <> Stat::ALL then rec.SetRange(Status,Stat-1);
        CurrPage.Update(false);
    end;    
    Var 
    Exdate: date;
    Stat:option ALL,Fail,Pass;
}