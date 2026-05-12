using System.Globalization;
using System.Text.Json;

namespace QbConnectService.Qb.Ops;

public static class ArgReader
{
    public static string? String(IReadOnlyDictionary<string, object?> args, string key)
    {
        if (!args.TryGetValue(key, out var value) || value is null)
        {
            return null;
        }

        var text = value switch
        {
            string s => s,
            JsonElement json when json.ValueKind == JsonValueKind.Null || json.ValueKind == JsonValueKind.Undefined => null,
            JsonElement json when json.ValueKind == JsonValueKind.String => json.GetString(),
            JsonElement json => json.ToString(),
            _ => value.ToString(),
        };

        return string.IsNullOrWhiteSpace(text) ? null : text.Trim();
    }

    public static bool? Bool(IReadOnlyDictionary<string, object?> args, string key)
    {
        if (!args.TryGetValue(key, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            bool b => b,
            JsonElement json when json.ValueKind == JsonValueKind.True => true,
            JsonElement json when json.ValueKind == JsonValueKind.False => false,
            string s when bool.TryParse(s, out var parsed) => parsed,
            JsonElement json when json.ValueKind == JsonValueKind.String && bool.TryParse(json.GetString(), out var parsed) => parsed,
            _ => null,
        };
    }

    public static DateOnly? Date(IReadOnlyDictionary<string, object?> args, string key)
    {
        if (!args.TryGetValue(key, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            DateOnly date => date,
            DateTime dateTime => DateOnly.FromDateTime(dateTime),
            JsonElement json when json.ValueKind == JsonValueKind.String => ParseDate(key, json.GetString()),
            string s => ParseDate(key, s),
            _ => throw new ArgumentException($"Argument '{key}' must be a yyyy-MM-dd date."),
        };
    }

    public static IReadOnlyDictionary<string, object?>? Dict(IReadOnlyDictionary<string, object?> args, string key)
    {
        if (!args.TryGetValue(key, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            IReadOnlyDictionary<string, object?> ro => ro,
            IDictionary<string, object?> dict => new Dictionary<string, object?>(dict, StringComparer.Ordinal),
            JsonElement json when json.ValueKind == JsonValueKind.Object => ToDictionary(json),
            _ => null,
        };
    }

    private static DateOnly? ParseDate(string key, string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var trimmed = value.Trim();
        if (DateOnly.TryParseExact(trimmed, "yyyy-MM-dd", CultureInfo.InvariantCulture, DateTimeStyles.None, out var exact))
        {
            return exact;
        }

        if (DateOnly.TryParse(trimmed, CultureInfo.InvariantCulture, DateTimeStyles.None, out var parsed))
        {
            return parsed;
        }

        throw new ArgumentException($"Argument '{key}' must be a yyyy-MM-dd date.");
    }

    private static IReadOnlyDictionary<string, object?> ToDictionary(JsonElement json)
    {
        var result = new Dictionary<string, object?>(StringComparer.Ordinal);

        foreach (var property in json.EnumerateObject())
        {
            result[property.Name] = ConvertJson(property.Value);
        }

        return result;
    }

    private static object? ConvertJson(JsonElement value) =>
        value.ValueKind switch
        {
            JsonValueKind.Null or JsonValueKind.Undefined => null,
            JsonValueKind.String => value.GetString(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Number => value.ToString(),
            JsonValueKind.Object => ToDictionary(value),
            JsonValueKind.Array => value.EnumerateArray().Select(ConvertJson).ToList(),
            _ => value.ToString(),
        };
}
