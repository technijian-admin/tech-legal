using System.Runtime.InteropServices;
using QbConnectService.Qb;

namespace QbConnectService.Tests;

public sealed class QbErrorsTests
{
    public static TheoryData<int, string> KnownCodes => new()
    {
        { unchecked((int)0x80040401), "QB_ACCESS_FAILED" },
        { unchecked((int)0x80040402), "QB_UNEXPECTED_ERROR" },
        { unchecked((int)0x80040408), "QB_COULD_NOT_START" },
        { unchecked((int)0x8004040A), "QB_DIFFERENT_FILE_OPEN" },
        { unchecked((int)0x8004040D), "QB_INVALID_TICKET" },
        { unchecked((int)0x80040410), "QB_MODE_MISMATCH" },
        { unchecked((int)0x80040414), "QB_MODAL_DIALOG" },
        { unchecked((int)0x80040416), "QB_NO_FILE_SPECIFIED" },
        { unchecked((int)0x8004041A), "QB_NO_PERMISSION" },
        { unchecked((int)0x80040420), "QB_ACCESS_DENIED" },
        { unchecked((int)0x80040421), "QB_PASSTHROUGH" },
        { unchecked((int)0x80040422), "QB_REQUIRES_SINGLE_USER" },
        { unchecked((int)0x80040154), "REGDB_E_CLASSNOTREG" },
    };

    [Theory]
    [MemberData(nameof(KnownCodes))]
    public void Lookup_returns_expected_mapping_for_known_code(int code, string expectedName)
    {
        var error = QbErrors.Lookup(code);

        Assert.Equal(expectedName, error.Name);
        Assert.False(string.IsNullOrWhiteSpace(error.Message));
        Assert.False(string.IsNullOrWhiteSpace(error.RemediationHint));
    }

    [Fact]
    public void Lookup_returns_unknown_mapping_for_unmapped_code()
    {
        var error = QbErrors.Lookup(unchecked((int)0x80041234));

        Assert.Equal("QB_UNKNOWN", error.Name);
    }

    [Fact]
    public void IsDeadTicket_identifies_only_the_dead_ticket_code()
    {
        Assert.True(QbErrors.IsDeadTicket(unchecked((int)0x8004040D)));
        Assert.False(QbErrors.IsDeadTicket(unchecked((int)0x80040420)));
    }

    [Fact]
    public void QbException_From_maps_the_hresult()
    {
        var exception = QbException.From(new COMException("boom", unchecked((int)0x80040408)));

        Assert.Equal("QB_COULD_NOT_START", exception.Error.Name);
    }

    [Fact]
    public void CastFailure_returns_the_cast_failure_mapping()
    {
        var error = QbErrors.CastFailure("no interface");

        Assert.Equal("QB_RP2_CAST_FAILED", error.Name);
    }
}
