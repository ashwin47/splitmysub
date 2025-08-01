require "test_helper"

class BillingCyclesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:test_user)
    @project = projects(:netflix)
    @billing_cycle = billing_cycles(:netflix_current)
    @member = users(:member_user)

    # Ensure test_user owns the netflix project
    @project.update!(user: @user)

    # Clear existing memberships and create fresh ones
    @project.project_memberships.destroy_all

    # Create a project membership for member_user
    ProjectMembership.create!(project: @project, user: @member, role: "member")

    # Sign in as project owner
    sign_in_as(@user)
  end

  test "should get index as project owner" do
    get project_billing_cycles_path(@project)
    assert_response :success
    assert_includes response.body, "billing_cycles/Index"
  end

    test "should get index as project member" do
    # Sign in as member
    sign_in_as(@member)

    get project_billing_cycles_path(@project)
    assert_response :success
  end

    test "should not get index for non-member" do
    other_user = users(:other_user)
    sign_in_as(other_user)

    get project_billing_cycles_path(@project)
    assert_redirected_to root_path
    assert_equal "Project not found or access denied.", flash[:alert]
  end

  test "should show billing cycle" do
    get project_billing_cycle_path(@project, @billing_cycle)
    assert_response :success
  end

  test "should get new as project owner" do
    get new_project_billing_cycle_path(@project)
    assert_response :success
  end

    test "should not get new as project member" do
    # Sign in as member
    sign_in_as(@member)

    get new_project_billing_cycle_path(@project)
    assert_redirected_to root_path # Members cannot access the new form
    assert_equal "Access denied.", flash[:alert]
  end

  test "should create billing cycle with valid params" do
    assert_difference("BillingCycle.count") do
      post project_billing_cycles_path(@project), params: {
        billing_cycle: {
          due_date: 1.month.from_now.to_date,
          total_amount: 15.99
        }
      }
    end

    assert_redirected_to project_billing_cycle_path(@project, BillingCycle.last)
    assert_equal "Billing cycle created successfully!", flash[:notice]
  end

  test "should not create billing cycle with invalid params" do
    assert_no_difference("BillingCycle.count") do
      post project_billing_cycles_path(@project), params: {
        billing_cycle: {
          due_date: nil,
          total_amount: -5
        }
      }
    end

    assert_response :success
    assert_includes response.body, "Due date can&#39;t be blank"
  end

  test "should not create billing cycle with past due date" do
    assert_no_difference("BillingCycle.count") do
      post project_billing_cycles_path(@project), params: {
        billing_cycle: {
          due_date: 1.day.ago.to_date,
          total_amount: 15.99
        }
      }
    end

    assert_response :success
    assert_includes response.body, "Due date cannot be in the past"
  end

  test "should get edit as project owner" do
    get edit_project_billing_cycle_path(@project, @billing_cycle)
    assert_response :success
  end

  test "should update billing cycle with valid params" do
    new_amount = 20.99
    patch project_billing_cycle_path(@project, @billing_cycle), params: {
      billing_cycle: {
        total_amount: new_amount
      }
    }

    assert_redirected_to project_billing_cycle_path(@project, @billing_cycle)
    assert_equal "Billing cycle updated successfully!", flash[:notice]
    assert_equal new_amount, @billing_cycle.reload.total_amount
  end

  test "should not update billing cycle with invalid params" do
    original_amount = @billing_cycle.total_amount
    patch project_billing_cycle_path(@project, @billing_cycle), params: {
      billing_cycle: {
        total_amount: -5
      }
    }

    assert_response :success
    assert_equal original_amount, @billing_cycle.reload.total_amount
  end

  test "should destroy billing cycle as project owner" do
    assert_difference("BillingCycle.count", -1) do
      delete project_billing_cycle_path(@project, @billing_cycle)
    end

    assert_redirected_to project_billing_cycles_path(@project)
    assert_equal "Billing cycle deleted successfully!", flash[:notice]
  end

    test "should not destroy billing cycle as project member" do
    # Sign in as member
    sign_in_as(@member)

    assert_no_difference("BillingCycle.count") do
      delete project_billing_cycle_path(@project, @billing_cycle)
    end

    assert_redirected_to root_path
  end

    test "should generate upcoming cycles" do
    # Clear existing billing cycles to test generation
    @project.billing_cycles.destroy_all

    # For a monthly project, the service generates 3 months ahead = 3 cycles
    assert_difference("BillingCycle.count", 3) do
      post generate_upcoming_project_billing_cycles_path(@project)
    end

    assert_redirected_to project_billing_cycles_path(@project)
    assert_includes flash[:notice], "Generated"
  end

  test "should filter billing cycles by status" do
    get project_billing_cycles_path(@project), params: { filter: "upcoming" }
    assert_response :success

    get project_billing_cycles_path(@project), params: { filter: "overdue" }
    assert_response :success

    get project_billing_cycles_path(@project), params: { filter: "due_soon" }
    assert_response :success
  end

  test "should search billing cycles by amount" do
    get project_billing_cycles_path(@project), params: { search: "15.99" }
    assert_response :success
  end

  test "should sort billing cycles" do
    get project_billing_cycles_path(@project), params: { sort: "due_date_asc" }
    assert_response :success

    get project_billing_cycles_path(@project), params: { sort: "amount_desc" }
    assert_response :success
  end

  test "should include billing cycle stats in index" do
    get project_billing_cycles_path(@project)
    assert_response :success

    # Check that the response contains the Inertia component
    assert_includes response.body, "billing_cycles/Index"
  end

  test "should include payment stats in show" do
    get project_billing_cycle_path(@project, @billing_cycle)
    assert_response :success

    # Check that the response contains the Inertia component
    assert_includes response.body, "billing_cycles/Show"
  end

  test "should include members who paid and haven't paid in show" do
    get project_billing_cycle_path(@project, @billing_cycle)
    assert_response :success

    # Check that the response contains the Inertia component
    assert_includes response.body, "billing_cycles/Show"
  end

  test "should handle non-existent billing cycle" do
    get project_billing_cycle_path(@project, 99999)
    assert_response :not_found
  end

  test "should handle non-existent project" do
    get project_billing_cycles_path(99999)
    assert_redirected_to root_path
    assert_equal "Project not found or access denied.", flash[:alert]
  end

  test "should archive billing cycle as project owner" do
    assert_not @billing_cycle.archived?

    patch archive_project_billing_cycle_path(@project, @billing_cycle)

    assert_redirected_to project_billing_cycles_path(@project)
    assert_equal "Billing cycle archived successfully!", flash[:notice]
    assert @billing_cycle.reload.archived?
  end

  test "should unarchive billing cycle as project owner" do
    @billing_cycle.archive!
    assert @billing_cycle.archived?

    patch unarchive_project_billing_cycle_path(@project, @billing_cycle)

    assert_redirected_to project_billing_cycles_path(@project)
    assert_equal "Billing cycle unarchived successfully!", flash[:notice]
    assert_not @billing_cycle.reload.archived?
  end

  test "should not archive billing cycle as project member" do
    sign_in_as(@member)

    patch archive_project_billing_cycle_path(@project, @billing_cycle)

    assert_redirected_to root_path
    assert_not @billing_cycle.reload.archived?
  end

  test "should get project payments as project member" do
    sign_in_as(@member)

    get project_payments_path(@project)
    assert_response :success
    assert_includes response.body, "payments/ProjectIndex"
  end

  test "should get adjust form as project owner" do
    get adjust_project_billing_cycle_path(@project, @billing_cycle)
    assert_response :success
  end

  test "should adjust billing cycle amount as project owner" do
    original_amount = @billing_cycle.total_amount
    new_amount = 25.99
    reason = "Price increase"

    post adjust_project_billing_cycle_path(@project, @billing_cycle), params: {
      adjustment: {
        new_amount: new_amount,
        reason: reason
      }
    }

    assert_redirected_to project_billing_cycle_path(@project, @billing_cycle)
    assert_equal "Billing cycle adjusted successfully!", flash[:notice]

    @billing_cycle.reload
    assert_equal new_amount, @billing_cycle.total_amount
    assert_equal original_amount, @billing_cycle.original_amount
    assert_equal reason, @billing_cycle.adjustment_reason
    assert @billing_cycle.adjusted?
  end

  test "should adjust billing cycle due date as project owner" do
    original_due_date = @billing_cycle.due_date
    new_due_date = 2.weeks.from_now.to_date
    reason = "Extended deadline"

    post adjust_project_billing_cycle_path(@project, @billing_cycle), params: {
      adjustment: {
        new_due_date: new_due_date.to_s,
        reason: reason
      }
    }

    assert_redirected_to project_billing_cycle_path(@project, @billing_cycle)
    assert_equal "Billing cycle adjusted successfully!", flash[:notice]

    @billing_cycle.reload
    assert_equal new_due_date, @billing_cycle.due_date
    assert_equal original_due_date, @billing_cycle.original_due_date
    assert_equal reason, @billing_cycle.adjustment_reason
    assert @billing_cycle.adjusted?
  end

  test "should not adjust billing cycle as project member" do
    sign_in_as(@member)

    get adjust_project_billing_cycle_path(@project, @billing_cycle)
    assert_redirected_to root_path
  end

  test "should filter archived billing cycles" do
    archived_cycle = @project.billing_cycles.create!(
      due_date: 1.month.from_now,
      total_amount: 15.99,
      archived: true
    )

    # Test showing active cycles (default)
    get project_billing_cycles_path(@project)
    assert_response :success

    # Test showing archived cycles
    get project_billing_cycles_path(@project), params: { show_archived: "true" }
    assert_response :success
  end

  test "should handle adjustment errors gracefully" do
    post adjust_project_billing_cycle_path(@project, @billing_cycle), params: {
      adjustment: {
        new_amount: "invalid",
        reason: "Test"
      }
    }

    assert_redirected_to project_billing_cycle_path(@project, @billing_cycle)
    assert_includes flash[:alert], "Failed to adjust billing cycle"
  end

  private

  def sign_in_as(user)
    magic_link = MagicLink.generate_for_user(user, expires_in: 30.minutes)
    get verify_magic_link_url(token: magic_link.token)
  end
end
