/*
codeunit 80001 "PC Report Support"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::ReportManagement, 'OnAfterSubstituteReport', '', false, false)]
    local procedure OnSubstituteReport(ReportId: Integer; var NewReportId: Integer)
    begin
        Case ReportID of
            Report::"Remittance Advice - Journal": NewReportId := Report::"PC Remittance Advice - Journal";
        end;    
    end;
}
*/

