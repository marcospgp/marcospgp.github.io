/*
  Written by ChatGPT.

  Checks or sorts markdown headers alphabetically within their respective levels, depending on the --write flag.

  Usage:
    dotnet tool install -g dotnet-script
    (add dotnet-script to $PATH)
    Check: dotnet-script SortMarkdownHeaders.csx notes.md
    Sort: dotnet-script SortMarkdownHeaders.csx --write notes.md
*/

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

class MarkdownNode
{
    public int Level { get; set; }
    public string Header { get; set; }
    public List<string> Content { get; set; } = new List<string>();
    public List<MarkdownNode> Children { get; set; } = new List<MarkdownNode>();
    public MarkdownNode Parent { get; set; }

    public MarkdownNode(int level, string header, MarkdownNode parent)
    {
        Level = level;
        Header = header;
        Parent = parent;
    }

    public void AddContentLine(string line)
    {
        Content.Add(line);
    }
}

class SortingHelper
{
    public static List<string> GetSortingIssues(MarkdownNode rootNode)
    {
        var sortingIssues = new List<string>();
        CheckSortingRecursively(rootNode, sortingIssues);
        return sortingIssues;
    }

    private static void CheckSortingRecursively(MarkdownNode node, List<string> sortingIssues)
    {
        // Check sorting issues for immediate children of the current node
        for (int i = 0; i < node.Children.Count - 1; i++)
        {
            // Compare the headers of adjacent children
            if (string.Compare(node.Children[i].Header, node.Children[i + 1].Header, StringComparison.OrdinalIgnoreCase) > 0)
            {
                sortingIssues.Add($"The header '{node.Children[i].Header}' at level {node.Children[i].Level} should appear after '{node.Children[i + 1].Header}' at level {node.Children[i + 1].Level}");
            }
        }

        // Recursively check sorting issues for each child node
        foreach (var child in node.Children)
        {
            CheckSortingRecursively(child, sortingIssues);
        }
    }
}

var writeChanges = Args.Contains("--write");
var filePath = Args.LastOrDefault(arg => !arg.StartsWith("--"));

if (string.IsNullOrEmpty(filePath) || !File.Exists(filePath))
{
    Console.Error.WriteLine("Usage: dotnet-script SortMarkdownHeaders.csx [--write] <path to markdown file>");
    Environment.Exit(1);
}

var lines = File.ReadAllLines(filePath);
var rootNode = new MarkdownNode(0, null, null); // Root node without a header
MarkdownNode currentNode = rootNode;
bool inFencedCodeBlock = false;

// Find the index of the first header line
int firstHeaderIndex = lines.ToList().FindIndex(line => line.TrimStart().StartsWith("#"));
if (firstHeaderIndex > 0)
{
    for (int i = 0; i < firstHeaderIndex; i++)
    {
        rootNode.AddContentLine(lines[i]);
    }
}

foreach (var line in lines.Skip(firstHeaderIndex))
{
    var trimmedLine = line.Trim();

    if (trimmedLine.StartsWith("```"))
    {
        inFencedCodeBlock = !inFencedCodeBlock;
    }

    if (inFencedCodeBlock || (!trimmedLine.StartsWith("#") && currentNode != rootNode))
    {
        currentNode.AddContentLine(line);
        continue;
    }

    if (trimmedLine.StartsWith("#"))
    {
        var level = trimmedLine.TakeWhile(c => c == '#').Count();
        var header = trimmedLine.Substring(level).Trim();
        while (currentNode != rootNode && level <= currentNode.Level)
        {
            currentNode = currentNode.Parent;
        }
        var newNode = new MarkdownNode(level, header, currentNode);
        currentNode.Children.Add(newNode);
        currentNode = newNode;
    }
    else
    {
        currentNode.AddContentLine(line);
    }
}

var sortingIssues = SortingHelper.GetSortingIssues(rootNode);
if (sortingIssues.Any())
{
    foreach (var issue in sortingIssues)
    {
        Console.WriteLine(issue);
    }
    if (writeChanges)
    {
        Console.WriteLine("Sorting issues found. Updating the markdown file...");

        // Sort the headers alphabetically and update the file
        SortAndWriteHeaders(rootNode, filePath);

        Console.WriteLine("Markdown file updated successfully.");
        Environment.Exit(0); // Exit with success code if issues were corrected
    }
    else
    {
        Console.WriteLine("Review the sorting issues listed above. Use --write to sort and update the markdown file.");
        Environment.Exit(1); // Exit with error code if sorting issues were found
    }
}
else
{
    if (writeChanges)
    {
        Console.WriteLine("No sorting issues found. The markdown file is already sorted.");
    }
    else
    {
        Console.WriteLine("No sorting issues found.");
    }
    Environment.Exit(0); // Exit with success code if no issues were found
}

void SortAndWriteHeaders(MarkdownNode node, string filePath)
{
    var sortedLines = new List<string>();
    WriteNode(node, sortedLines);
    File.WriteAllLines(filePath, sortedLines);
}

void WriteNode(MarkdownNode node, List<string> lines)
{
    if (node.Header != null)
    {
        lines.Add(new string('#', node.Level) + " " + node.Header);
    }
    lines.AddRange(node.Content);

    // Sort children nodes alphabetically
    foreach (var child in node.Children.OrderBy(child => child.Header, StringComparer.OrdinalIgnoreCase))
    {
        WriteNode(child, lines);
    }
}
