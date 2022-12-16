codeunit 80007 PCReportSupport
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer;
    var NewReportId: Integer)begin
        Case ReportID of // Sales Invoice
        206: NewReportId:=80004;
        // Remittance Advice
        399: NewReportId:=80000;
        //Purchase Order
        405: NewReportId:=80001;
        //Purchase Credit Note
        407: NewReportId:=80003;
        //Purchase Return Order
        6641: NewReportId:=80002;
        //Remittance advise Ledger Entries
        400: NewReportId:=80005;
        end;
    end;
}
