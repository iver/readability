defmodule Readability.CandidateFinder do
  @moduledoc """
  The builing and finding candidates  engine
  It traverses the HTML tree searching, removing, socring nodes
  """

  alias Readability.Candidate
  alias Readability.Candidate.Scoring
  alias Readability.Helper

  @type html_tree :: tuple | list
  @type options :: list

  @doc """
  Find candidates that shuld be meaningful article by analysing nodes
  """
  @spec find(html_tree, options, number) :: [Candidate.t()]
  def find(_, opts \\ [], tree_depth \\ 0)
  def find([], _, _), do: []

  def find([h | t], opts, tree_depth) do
    [find(h, opts, tree_depth) | find(t, opts, tree_depth)]
    |> List.flatten()
  end

  def find(text, _, _) when is_binary(text), do: []

  def find({tag, attrs, inner_tree}, opts, tree_depth) do
    html_tree = {tag, attrs, inner_tree}

    if candidate?(html_tree) do
      candidate = %Candidate{
        html_tree: html_tree,
        score: Scoring.calc_score(html_tree, opts),
        tree_depth: tree_depth
      }

      [candidate | find(inner_tree, opts, tree_depth + 1)]
    else
      find(inner_tree, opts, tree_depth + 1)
    end
  end

  @doc """
  Find the highest score candidate.
  """
  @spec find_best_candidate([Candidate.t()]) :: Candidate.t()
  def find_best_candidate([]), do: nil

  def find_best_candidate(candidates) do
    candidates
    |> Enum.max_by(fn candidate -> candidate.score end)
  end

  defp candidate?(_, depth \\ 0)
  defp candidate?(_, depth) when depth > 2, do: false
  defp candidate?([h | t], depth), do: candidate?(h, depth) || candidate?(t, depth)
  defp candidate?([], _), do: false
  defp candidate?(text, _) when is_binary(text), do: false

  defp candidate?({_, _, inner_tree} = html_tree, depth) do
    if Helper.candidate_tag?(html_tree) do
      true
    else
      candidate?(inner_tree, depth + 1)
    end
  end
end
