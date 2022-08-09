page 80005 "PC EDI Execution Log"
{
    
    ApplicationArea = All;
    Caption = 'EDI Execution Log';
    PageType = List;
    SourceTable = "PC EDI Execution Log";
    UsageCategory = Lists;
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    
    layout
    {
        area(content)
        {
            field("PO Number Filter"; PONum)
            {
                ApplicationArea = All;
                Style = Strong;
                trigger OnDrillDown()
                var
                    Pg:Page "Purchase Order List";
                    PurchHdr:Record "Purchase Header";
                begin
                    PurchHdr.reset;
                    PurchHdr.Setrange("Document Type",PurchHdr."Document Type"::Order);
                    PurchHdr.SetRange("Order Type",PurchHdr."Order Type"::Fulfilo);
                    PurchHdr.Setrange("EDI Status",PurchHdr."EDI Status"::"EDI Vendor");   
                    Clear(PONum);
                    Pg.SetTableView(PurchHdr);
                    Pg.LookupMode := true;
                    if pg.RunModal() = Action::LookupOK then
                    begin
                        Pg.GetRecord(PurchHdr);
                        Ponum := PurchHdr."No."
                    end;
                    Setfilters;
                end;
                trigger OnAssistEdit()
                begin
                    Clear(PONum);
                    Setfilters();
                end;
            }
            repeater(General)
            {
                field("Excution Date/Time"; Rec."Execution Date/Time")
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    trigger OnDrillDown()
                    var
                        PG:PAGE "Purchase Order";
                        PH:Record "Purchase Header";
                    begin
                        if PH.Get(PH."Document Type"::Order,Rec."Purchase Order No.") then
                        begin
                            PG.SetRecord(PH);
                            Pg.Run();   
                        end
                        else
                            Message('PO Not found');
                    end;    
                }
                field(Vendor; Rec.Vendor)
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("EDI Execution Action"; Rec."EDI Execution Action")
                {
                    ApplicationArea = All;
                }
                field("Transaction Status";rec."Transaction Status")
                {
                    ApplicationArea = All;
                    Style = Strong;
                }
            }
        }
    }
    local procedure Setfilters()
    Begin
        Rec.reset;
        If PONum <> '' then rec.Setrange("Purchase Order No.",PONum);
        CurrPage.update(false);    
    End;
    
    trigger OnOpenPage()
    begin
        Rec.reset;
        Rec.Setfilter("Execution Date/Time",'<=%1',CreateDateTime(CalcDate('-1M',Today),0T));
        If Rec.findset then Rec.DeleteAll();
        Rec.reset;
    end;
    var
        PONum:code[20];

}
